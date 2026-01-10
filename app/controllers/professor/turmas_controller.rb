class Professor::TurmasController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!

  def index
    @turmas = current_professor.turmas.includes(:alunos, :frequencias)
    @estatisticas = calcular_estatisticas(@turmas)
  end

  def historico
    # ============================
    # 0. Turma (aceita :id ou :turma_id)
    # ============================
    turma_id = params[:id] || params[:turma_id]

    @turma = current_professor.turmas.find_by(id: turma_id)
    unless @turma
      redirect_to professor_turmas_path, alert: "Você não tem acesso a essa turma."
      return
    end

    # ============================
    # 1. Disciplinas do professor
    # ============================
    disciplinas_professor = current_professor.disciplinas
    disciplinas_professor_ids = disciplinas_professor.pluck(:id)

    # ============================
    # 2. Disciplina ativa (SEGURA)
    # ============================
    if params[:disciplina_id].present? &&
      disciplinas_professor_ids.include?(params[:disciplina_id].to_i)

      @disciplina_ativa = disciplinas_professor.find(params[:disciplina_id])
    else
      @disciplina_ativa = disciplinas_professor.first
    end

    # ============================
    # 3. Parâmetros de data
    # ============================
    @mes = params[:mes]&.to_i || Date.current.month
    @ano = params[:ano]&.to_i || Date.current.year

    @data_inicio = Date.new(@ano, @mes, 1)
    @data_fim = @data_inicio.end_of_month

    # ============================
    # 4. Base query de frequências
    # ============================
    frequencias_query = Frequencia
      .where(turma: @turma)
      .where(disciplina_id: disciplinas_professor_ids)
      .where(data_aula: @data_inicio..@data_fim)

    # ============================
    # 5. Aplica filtro APENAS se for válido
    # ============================
    if @disciplina_ativa
      frequencias_query = frequencias_query.where(disciplina_id: @disciplina_ativa.id)
    end

    # ============================
    # 6. Buscar frequências
    # ============================
    @frequencias = frequencias_query
      .includes(:disciplina, :frequencia_alunos)
      .order(:data_aula)

    # ============================
    # 7. Datas com frequência
    # ============================
    @datas_com_frequencia = @frequencias.map(&:data_aula).uniq

    # ============================
    # 8. Estatísticas
    # ============================
    @estatisticas_mes = calcular_estatisticas_mes(@frequencias)
  end


  private

  def calcular_estatisticas(turmas)
    turma_ids = turmas.pluck(:id)
    
    total_turmas = turmas.count
    total_alunos = Aluno.where(turma_id: turma_ids).count
    todas_frequencias = Frequencia.where(turma_id: turma_ids)
    frequencias_registradas = todas_frequencias.count
    turmas_com_frequencia_hoje = todas_frequencias.where(data_aula: Date.current).pluck(:turma_id).uniq.count

    {
      total_turmas: total_turmas,
      total_alunos: total_alunos,
      frequencias_registradas: frequencias_registradas,
      turmas_com_frequencia_hoje: turmas_com_frequencia_hoje
    }
  end
  
  def calcular_estatisticas_mes(frequencias)
    total_aulas = frequencias.count
    
    if total_aulas > 0
      # Pega o total de alunos da primeira frequência ou da turma
      total_alunos = frequencias.first&.total_alunos || @turma.alunos.count
      
      # Soma todas as presenças
      total_presencas = frequencias.sum(&:total_presentes)
      
      # Calcula o total possível de presenças
      total_possivel = total_aulas * total_alunos
      
      # Calcula a média de presença
      media_presenca = total_possivel > 0 ? ((total_presencas.to_f / total_possivel) * 100).round(1) : 0
    else
      total_alunos = @turma.alunos.count
      media_presenca = 0
    end
    
    {
      total_aulas: total_aulas,
      total_alunos: total_alunos,
      media_presenca: media_presenca
    }
  end
end