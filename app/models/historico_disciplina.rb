class HistoricoDisciplina < ApplicationRecord
  belongs_to :historico_escolar

  validates :disciplina_nome, presence: true

  def frequencia_percentual
    return nil if aulas_dadas.zero?
    presencas = aulas_dadas - total_faltas
    (presencas.to_f / aulas_dadas * 100).round(2)
  end

  def tipo_nota
    nota_b1.present? ? :numerica : :conceito
  end
end