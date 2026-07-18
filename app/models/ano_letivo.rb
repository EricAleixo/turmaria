class AnoLetivo < ApplicationRecord
  has_many :turmas, dependent: :destroy
  has_many :declaracoes, dependent: :nullify
  accepts_nested_attributes_for :turmas
  belongs_to :escola
 
  validates :ano,
    presence: true,
    uniqueness: { scope: :escola_id, message: "Já existe um ano letivo com esse número para esta escola." },
    length: {maximum: 4}

  validates :data_inicio, presence: true, length: {maximum: 11}
  validates :data_fim, presence: true, length: {maximum: 11}
end
 