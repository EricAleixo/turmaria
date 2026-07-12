class RegistroDeNota < ApplicationRecord
  require Rails.root.join('app', 'services', 'notas', 'calculadora_bimestral.rb')

  self.table_name = 'registros_de_notas'

  CONCEITOS_VALIDOS = %w[a b c d].freeze

  # Associações
  belongs_to :aluno
  belongs_to :avaliacao_configuracao, class_name: 'AvaliacaoConfiguracao'
  has_one :turma,      through: :avaliacao_configuracao
  has_one :disciplina, through: :avaliacao_configuracao

  # Setter normalizado para PT-BR
  def valor=(value)
    if value.is_a?(String)
      value = value.delete('.').tr(',', '.')
    end
    super(value)
  end

  # Validações
  validates :aluno_id, uniqueness: {
    scope: :avaliacao_configuracao_id,
    message: "já possui um registro para esta avaliação."
  }

  validate :valor_coerente_com_tipo_avaliacao

  # Callbacks
  after_save    :recalcular_media_bimestral
  after_destroy :recalcular_media_bimestral

  private

  def turma_da_avaliacao
    avaliacao_configuracao&.turma
  end

  def valor_coerente_com_tipo_avaliacao
    turma_record = turma_da_avaliacao
    return unless turma_record.present?

    if turma_record.usa_conceito?
      unless CONCEITOS_VALIDOS.include?(conceito.to_s.downcase.strip)
        errors.add(:conceito, "deve ser um conceito válido: A, B, C ou D")
      end
    else
      unless valor.present?
        errors.add(:valor, "não pode ficar em branco")
        return
      end
      v = valor.to_f
      errors.add(:valor, "deve ser maior ou igual a 0")  if v < 0
      errors.add(:valor, "deve ser menor ou igual a 10") if v > 10
    end
  end

  def recalcular_media_bimestral
    ::Notas::CalculadoraBimestral.new(self).call
  end
end