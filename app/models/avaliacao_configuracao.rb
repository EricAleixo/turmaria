class AvaliacaoConfiguracao < ApplicationRecord
  self.table_name = 'avaliacoes_configuracoes'

  # Associações
  belongs_to :turma
  belongs_to :disciplina
  has_many :registros_de_notas, class_name: 'RegistroDeNota', dependent: :destroy

  belongs_to :avaliacao_original, class_name: 'AvaliacaoConfiguracao',
             foreign_key: 'avaliacao_original_id',
             optional: true

  has_many :avaliacoes_recuperacao, class_name: 'AvaliacaoConfiguracao',
           foreign_key: 'avaliacao_original_id',
           dependent: :delete_all

  # Validações
  validates :bimestre, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :nome, presence: true, uniqueness: { scope: [ :turma_id, :disciplina_id, :bimestre ] }

  validates :avaliacao_original_id, presence: true, if: :recuperacao?
  validates :avaliacao_original_id, absence: true, unless: :recuperacao?

  # Turmas de conceito não têm avaliações de recuperação
  validate :recuperacao_incompativel_com_conceito

  # Scopes
  scope :do_bimestre, ->(bimestre) { where(bimestre: bimestre) }
  scope :padrao,      -> { where(is_recuperacao: false) }
  scope :recuperacao, -> { where(is_recuperacao: true) }

  alias_attribute :recuperacao?, :is_recuperacao

  private

  def recuperacao_incompativel_com_conceito
    return unless recuperacao? && turma.present?

    if turma.usa_conceito?
      errors.add(:is_recuperacao, "não é permitida em turmas com avaliação por conceito")
    end
  end
end