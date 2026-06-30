class Aluno::HistoricosController < ApplicationController
  layout 'dashboard'
  before_action :authenticate_aluno!

  def index
    @historicos = HistoricoEscolar
      .includes(:escola, :ano_letivo, :historico_disciplinas)
      .where(aluno_id: current_aluno.id)
      .joins(:ano_letivo)
      .order('ano_letivos.ano ASC')

    # Dados ao vivo da escola/turma atual (sem histórico fechado)
    if current_aluno.turma.present?
      @turma_atual    = current_aluno.turma
      @ano_letivo_atual = @turma_atual.ano_letivo

      # Só mostra "ao vivo" se ainda não tem histórico fechado pra esse ano/escola
      ja_tem_historico = @historicos.any? do |h|
        h.escola_id == current_aluno.escola_id &&
        h.ano_letivo_id == @ano_letivo_atual.id
      end

      unless ja_tem_historico
        avaliacoes = AvaliacaoBimestral
          .includes(:disciplina)
          .where(aluno_id: current_aluno.id, turma_id: @turma_atual.id)
          .order('disciplinas.nome', :bimestre)

        @boletim_atual            = avaliacoes.group_by(&:disciplina)
        @frequencia_atual         = calcular_frequencia_por_disciplina(@turma_atual, current_aluno)
      end
    end
  end

  private

  def calcular_frequencia_por_disciplina(turma, aluno)
    aulas_dadas = Frequencia
      .where(turma_id: turma.id)
      .group(:disciplina_id)
      .count

    faltas = FrequenciaAluno
      .joins(:frequencia)
      .where(aluno_id: aluno.id, frequencias: { turma_id: turma.id }, status: 'falta')
      .group('frequencias.disciplina_id')
      .count

    aulas_dadas.each_with_object({}) do |(disciplina_id, total_aulas), hash|
      hash[disciplina_id] = {
        total_aulas:  total_aulas,
        total_faltas: faltas[disciplina_id] || 0
      }
    end
  end
end