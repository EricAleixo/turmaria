class Professor::FrequenciasController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!
  before_action :verificar_disciplinas, except: [:show, :index]
  before_action :set_frequencia, only: [:show, :edit, :update, :destroy, :update_presencas]
  before_action :set_turma_e_disciplina, only: [:new, :create]

  def index
    # 1. Carregamento da Tabela (O seu código original)
    @frequencias = current_professor.frequencias
                                    .includes(:turma, :disciplina, :frequencia_alunos, :alunos)
                                    .order(data_aula: :desc)

    # 2. CALCULO DAS ESTATISTICAS PARA O DASHBOARD 
    
    # Definindo os períodos
    current_month_start = Time.zone.now.beginning_of_month
    last_month_start = (Time.zone.now - 1.month).beginning_of_month
    
    # Base de Frequências do Professor
    frequencias_base = current_professor.frequencias
    
    # ----------------------------------------------------
    # CARD 1: Aulas no Mês (current_professor)
    aulas_mes_atual = frequencias_base.where(created_at: current_month_start..Time.zone.now.end_of_month).count
    aulas_mes_passado = frequencias_base.where(created_at: last_month_start..last_month_start.end_of_month).count
    
    # ----------------------------------------------------
    # CARD 2: Turmas Ativas (Turmas associadas ao professor)
    turmas_ativas = current_professor.turmas.distinct.count 
    
    # ----------------------------------------------------
    # CARD 3 & 4: Faltas e Média de Presença
    
    # Frequencia Aluno BASE (limitando para as frequencias do professor)
    frequencia_alunos_base = FrequenciaAluno.joins(:frequencia)
                                            .where(frequencias: { professor_id: current_professor.id })
    
    # Total de registros de presença/falta
    total_registros = frequencia_alunos_base.count
    
    # Total de faltas (tudo que não for 'presente')
    # Assumindo que o status de falta seja 'falta' ou outro valor diferente de 'presente'
    faltas_registradas = frequencia_alunos_base.where.not(status: 'presente').count
    
    # Cálculo da Média de Presença
    if total_registros > 0
        presencas = total_registros - faltas_registradas
        media_presenca = (presencas.to_f / total_registros) * 100
        media_presenca_formatada = "%.1f" % media_presenca
    else
        media_presenca_formatada = "0.0"
    end
    
    # ----------------------------------------------------
    # Agrupando os dados para o @estatisticas_gerais (usado na View)
    @estatisticas_gerais = {
        aulas_mes: aulas_mes_atual,
        aulas_mes_passado: aulas_mes_passado,
        faltas_registradas: faltas_registradas,
        media_presenca: "#{media_presenca_formatada}%",
        turmas_ativas: turmas_ativas,
        total_registros: total_registros
    }
    # ----------------------------------------------------
  end

  def set_turma_e_disciplina
    @turma = current_professor.turmas.find(params[:turma_id]) # Exige params[:turma_id]
    @disciplina = current_professor.disciplinas.find(params[:disciplina_id]) # Exige params
  end

  def show
    @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome')
  end

  def new
    @frequencia = @turma.frequencias.build(
      professor: current_professor,
      disciplina: @disciplina,
      data_aula: Date.current
    )
    @alunos = @turma.alunos.order(:nome)
  end

  def create
    @frequencia = @turma.frequencias.build(frequencia_params)
    @frequencia.professor = current_professor
    @frequencia.disciplina = @disciplina

    if @frequencia.save
      # Processar dados dos alunos enviados do formulário
      if params[:alunos].present?
        params[:alunos].each do |aluno_id, dados|
          @frequencia.frequencia_alunos.create!(
            aluno_id: aluno_id,
            status: dados[:status] || 'presente',
            observacoes: dados[:observacoes]
          )
        end
      else
        # Fallback: criar registros para todos os alunos como presente
        @turma.alunos.each do |aluno|
          @frequencia.frequencia_alunos.create!(
            aluno: aluno,
            status: 'presente'
          )
        end
      end

      redirect_to frequencia_path(@frequencia), 
                  notice: "Frequência de #{@disciplina.nome} registrada com sucesso!"
    else
      @alunos = @turma.alunos.order(:nome)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome')
    @disciplina = @frequencia.disciplina
    @turma = @frequencia.turma
  end

  def update
    if @frequencia.update(frequencia_params)
      redirect_to frequencia_path(@frequencia), 
                  notice: 'Frequência atualizada com sucesso!'
    else
      @frequencia_alunos = @frequencia.frequencia_alunos.includes(:aluno).order('alunos.nome')
      @disciplina = @frequencia.disciplina
      @turma = @frequencia.turma
      render :edit, status: :unprocessable_entity
    end
  end

  def update_presencas
    if params[:frequencia_alunos].present?
      params[:frequencia_alunos].each do |id, attrs|
        frequencia_aluno = @frequencia.frequencia_alunos.find(id)
        frequencia_aluno.update(attrs.permit(:status, :observacoes))
      end
      redirect_to frequencia_path(@frequencia), 
                  notice: 'Presenças atualizadas com sucesso!'
    else
      redirect_to frequencia_path(@frequencia), 
                  alert: 'Nenhuma alteração foi feita.'
    end
  end

  def destroy
    turma = @frequencia.turma
    @frequencia.destroy
    redirect_to professor_turma_path(turma), 
                notice: 'Frequência excluída com sucesso!'
  end

  private

  def verificar_disciplinas
    if current_professor.disciplinas.empty?
      redirect_to professor_turmas_path, 
                  alert: 'Você precisa ter pelo menos uma disciplina cadastrada para registrar frequências.'
    end
  end

  def set_frequencia
    @frequencia = current_professor.frequencias.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, 
                alert: 'Frequência não encontrada ou você não tem permissão para acessá-la.'
  end

  def set_turma_e_disciplina
    @turma = current_professor.turmas.find(params[:turma_id])
    @disciplina = current_professor.disciplinas.find(params[:disciplina_id])
    
    # Verificar se a disciplina pertence ao professor
    unless current_professor.disciplinas.include?(@disciplina)
      redirect_to professor_turmas_path, 
                  alert: 'Você não tem permissão para registrar frequência nesta disciplina.'
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, 
                alert: 'Turma ou disciplina não encontrada.'
  end

  def frequencia_params
    params.require(:frequencia).permit(:data_aula, :conteudo_trabalhado, :observacoes)
  end
end