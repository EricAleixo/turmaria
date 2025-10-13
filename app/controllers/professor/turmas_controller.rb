class Professor::TurmasController < Professor::BaseController
  layout 'dashboard'
  before_action :authenticate_professor!

  # Assume que layout, autenticação e base estão em Professor::BaseController

  def index
    # 1. Carrega as turmas do professor
    # Inclui :alunos e :frequencias (para a contagem no card individual na view)
    @turmas = current_professor.turmas.includes(:alunos, :frequencias)
    
    # 2. Define as estatísticas para os 4 cards de resumo
    @estatisticas = calcular_estatisticas(@turmas)
  end

  # GET /professor/turmas/:id/historico - CONSOLIDADO DE NOTAS E FALTAS
  def historico
    # 1. Encontra a turma garantindo que o professor a leciona.
    @turma = current_professor.turmas.find(params[:id])
    @alunos = @turma.alunos.order(:nome)
    
    # 2. Busca resultados FINAIS de notas (do seu schema `AvaliacoesBimestrais`)
    resultados_finais_turma = AvaliacoesBimestrais
      .where(turma: @turma)
      .where.not(nota_bimestre_final: nil) 
      .to_a 
      
    # 3. Busca o total de aulas registradas (usado para cálculo de faltas)
    total_aulas_registradas = Frequencia.where(turma: @turma).count
    
    # 4. Processa o desempenho individual dos alunos
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

    # 5. Calcula a Média Geral da Turma (para o card de resumo)
    todas_as_notas = resultados_finais_turma.pluck(:nota_bimestre_final).compact
    @media_geral_turma = todas_as_notas.empty? ? nil : (todas_as_notas.sum / todas_as_notas.size.to_f)
    
    # 6. Estatísticas Adicionais de Frequência
    @estatisticas_frequencia = {
      total_aulas: total_aulas_registradas
    }

  rescue ActiveRecord::RecordNotFound
    redirect_to professor_turmas_path, alert: 'Turma não encontrada ou você não tem permissão.'
  end

  private

  # Método auxiliar para calcular todas as estatísticas para a view Index
  def calcular_estatisticas(turmas)
    turma_ids = turmas.pluck(:id)
    
    # 1. Total de Turmas
    total_turmas = turmas.count
    
    # 2. Total de Alunos em TODAS as turmas do professor (sem duplicidade, se o aluno estivesse em N turmas, 
    # mas o `current_professor.turmas` já deve garantir a singularidade da turma no seu escopo)
    total_alunos = Aluno.where(turma_id: turma_ids).count
                        
    # 3. Total de Frequências Registradas (em todas as turmas do professor)
    todas_frequencias = Frequencia.where(turma_id: turma_ids)
    frequencias_registradas = todas_frequencias.count
    
    # 4. Total de Turmas com Frequência Registrada Hoje
    turmas_com_frequencia_hoje = todas_frequencias.where(data_aula: Date.current).pluck(:turma_id).uniq.count

    {
      total_turmas: total_turmas,
      total_alunos: total_alunos,
      frequencias_registradas: frequencias_registradas,
      turmas_com_frequencia_hoje: turmas_com_frequencia_hoje
    }
  end
end