class Professor::TurmasController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!

  def index
    @turmas = current_professor.turmas.includes(:alunos, :frequencias)
    @estatisticas = calcular_estatisticas(@turmas)
  end

  def historico
    # 1. Encontra a turma garantindo que o professor a leciona
    @turma = current_professor.turmas.find(params[:id])
    
    # 2. Parâmetros de data para o calendário
    @mes = params[:mes]&.to_i || Date.current.month
    @ano = params[:ano]&.to_i || Date.current.year
    
    # 3. Datas do mês
    @data_inicio = Date.new(@ano, @mes, 1)
    @data_fim = @data_inicio.end_of_month
    
    # 4. Pega os IDs das disciplinas que o professor leciona
    disciplinas_professor_ids = current_professor.disciplinas.pluck(:id)
    
    # 5. Base query para frequências do mês (apenas disciplinas que o professor leciona)
    frequencias_query = Frequencia
      .where(turma: @turma)
      .where(disciplina_id: disciplinas_professor_ids)
      .where(data_aula: @data_inicio..@data_fim)
    
    # 6. Filtro por disciplina (se selecionado)
    if params[:disciplina_id].present?
      disciplina_id = params[:disciplina_id].to_i
      # Verifica se a disciplina pertence ao professor atual
      if disciplinas_professor_ids.include?(disciplina_id)
        frequencias_query = frequencias_query.where(disciplina_id: disciplina_id)
        @disciplina_filtrada = current_professor.disciplinas.find(disciplina_id)
      end
    end
    
    # 7. Buscar frequências ordenadas
    @frequencias = frequencias_query
      .includes(:disciplina, :frequencia_alunos)
      .order(:data_aula)
    
    # 8. Datas que têm frequência registrada
    @datas_com_frequencia = @frequencias.map(&:data_aula).uniq
    
    # 9. Calcular estatísticas do mês (com filtro aplicado)
    @estatisticas_mes = calcular_estatisticas_mes(@frequencias)

  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, alert: 'Turma não encontrada ou você não tem permissão.'
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