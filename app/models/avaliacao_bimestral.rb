class AvaliacaoBimestral < ApplicationRecord
  self.table_name = 'avaliacoes_bimestrais'

  # Associações
  belongs_to :aluno
  belongs_to :turma
  belongs_to :disciplina

  # Enums
  enum :conceito, { d: 0, c: 1, b: 2, a: 3 }, prefix: true

  # Validações
  validates :bimestre, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :aluno_id, uniqueness: {
    scope: [ :turma_id, :disciplina_id, :bimestre ],
    message: "já tem uma avaliação final para este bimestre/disciplina."
  }

  validates :nota_bimestre_final, numericality: {
    allow_nil: true,
    greater_than_or_equal_to: 0.0,
    less_than_or_equal_to: 10.0
  }

  validate :coerencia_com_tipo_avaliacao

  # Helpers
  CONCEITO_LABELS = {
    "d" => "D — Insuficiente",
    "c" => "C — Regular",
    "b" => "B — Bom",
    "a" => "A — Excelente"
  }.freeze

  def conceito_label
    CONCEITO_LABELS[conceito]
  end

  # Lógica de negócio
  def calcular_media!
    return calcular_conceito! if turma.usa_conceito?

    configs = AvaliacaoConfiguracao.padrao
                                   .where(turma_id: turma_id, disciplina_id: disciplina_id, bimestre: bimestre)
    config_ids = configs.pluck(:id)

    total_notas = RegistroDeNota.where(aluno_id: aluno_id, avaliacao_configuracao_id: config_ids)
                                .sum(:valor)

    if configs.any?
      media = total_notas.to_f / configs.count
      self.nota_bimestre_final = media.round(2)
      save!
      media
    else
      self.nota_bimestre_final = nil
      save!
      nil
    end
  end

  private

  def calcular_conceito!
    # Conceito é lançado manualmente — não há cálculo automático.
    # Existe para proteger chamadas acidentais de calcular_media! em turmas de conceito.
    nil
  end

  def coerencia_com_tipo_avaliacao
    return unless turma.present?

    if turma.usa_nota? && conceito.present?
      errors.add(:conceito, "não deve ser preenchido em turmas com avaliação por nota")
    end

    if turma.usa_conceito? && nota_bimestre_final.present?
      errors.add(:nota_bimestre_final, "não deve ser preenchida em turmas com avaliação por conceito")
    end
  end
end