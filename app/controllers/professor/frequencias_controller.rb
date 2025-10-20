class Professor::FrequenciasController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!
  before_action :verificar_disciplinas, except: [:show, :index]
  before_action :set_frequencia, only: [:show, :edit, :update, :destroy, :update_presencas]
  before_action :set_turma_e_disciplina, only: [:new, :create]

  def index
    @frequencias = current_professor.frequencias
                                     .includes(:turma, :disciplina, :frequencia_alunos, :alunos)
                                     .order(data_aula: :desc)
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

      redirect_to professor_frequencia_path(@frequencia), 
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
      redirect_to professor_frequencia_path(@frequencia), 
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
      redirect_to professor_frequencia_path(@frequencia), 
                  notice: 'Presenças atualizadas com sucesso!'
    else
      redirect_to professor_frequencia_path(@frequencia), 
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