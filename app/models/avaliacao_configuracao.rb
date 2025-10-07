class AvaliacaoConfiguracao < ApplicationRecord
  # Associações
  belongs_to :turma
  belongs_to :disciplina
  has_many :registros_de_notas, dependent: :destroy
  
  # Validações
  validates :bimestre, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :nome, presence: true, uniqueness: { scope: [:turma_id, :disciplina_id, :bimestre] }
  validates :ordem, presence: true, numericality: { greater_than_or_equal_to: 1 }

  # Scopes úteis
  scope :do_bimestre, ->(bimestre) { where(bimestre: bimestre).order(:ordem) }
  scope :padrao, -> { where(is_recuperacao: false) }
  scope :recuperacao, -> { where(is_recuperacao: true) }

  # Alias para clareza
  alias_attribute :recuperacao?, :is_recuperacao
end