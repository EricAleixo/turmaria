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
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Parâmetros de data para o calendário
    @mes = params[:mes]&.to_i || Date.current.month
    @ano = params[:ano]&.to_i || Date.current.year
    
    # 3. Datas do mês
    @data_inicio = Date.new(@ano, @mes, 1)
    @data_fim = @data_inicio.end_of_month
    
    # 4. Buscar frequências do mês (apenas das disciplinas do professor)
    @frequencias = Frequencia
      .joins(:disciplina)
      .where(turma: @turma)
      .where(data_aula: @data_inicio..@data_fim)
      .includes(:disciplina) 
      .order(data_aula: :desc, created_at: :desc) 

    
    # 5. Datas que têm frequência registrada
    @datas_com_frequencia = @frequencias.pluck(:data_aula)
    
    # 6. Calcular estatísticas do mês (para os cards)
    @estatisticas_mes = {
      total_aulas: @frequencias.count,
      total_alunos: @turma.alunos.count,
      media_presenca: calcular_media_presenca(@frequencias)
    }
    
    # 7. Busca resultados FINAIS de notas (do schema AvaliacaoBimestral)
    resultados_finais_turma = AvaliacaoBimestral
      .where(turma: @turma)
      .where.not(nota_bimestre_final: nil)
      .to_a
      
    # 8. Busca o total de aulas registradas (usado para cálculo de faltas)
    total_aulas_registradas = Frequencia.where(turma: @turma).count
    
    # 9. Processa o desempenho individual dos alunos
    @alunos_com_resumo = @alunos.map do |aluno|
      # Média Anual Consolidada
      notas_do_aluno = resultados_finais_turma.select { |r| r.aluno_id == aluno.id }
      notas_validas = notas_do_aluno.map(&:nota_bimestre_final).compact
      media_anual = notas_validas.empty? ? nil : (notas_validas.sum / notas_validas.size.to_f)
      
      # Total de Faltas (apenas status 'falta')
      total_faltas = FrequenciaAluno.where(aluno: aluno, status: 'falta').count
      
      { 
        aluno: aluno, 
        media_anual: media_anual, 
        total_faltas: total_faltas
      }
    end

    # 10. Calcula a Média Geral da Turma (para o card de resumo)
    todas_as_notas = resultados_finais_turma.pluck(:nota_bimestre_final).compact
    @media_geral_turma = todas_as_notas.empty? ? nil : (todas_as_notas.sum / todas_as_notas.size.to_f)
    
    # 11. Estatísticas Adicionais de Frequência
    @estatisticas_frequencia = {
      total_aulas: total_aulas_registradas
    }

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
  
  def calcular_media_presenca(frequencias)
    return 0 if frequencias.empty?
    
    # CORREÇÃO para total_presencas
    total_presencas = FrequenciaAluno.joins(:frequencia)
                                    .where(frequencia: frequencias)
                                    .where(status: 'presente')
                                    .count
    
    # total_alunos deve ser a soma do count de alunos para cada aula
    # Se você não tem 'total_alunos' como coluna, precisamos do cálculo correto
    # O seu erro original (UndefinedColumn) também se aplica aqui se você tiver:
    # total_possivel = frequencias.sum(:total_alunos)
    
    # A maneira mais robusta de calcular o total de vagas é:
    total_possivel = FrequenciaAluno.joins(:frequencia)
                                    .where(frequencia: frequencias)
                                    .count # Conta todos os registros FrequenciaAluno
    
    return 0 if total_possivel.zero?
    
    ((total_presencas.to_f / total_possivel) * 100).round(1)
  end
end