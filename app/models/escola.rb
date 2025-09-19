class Escola < ApplicationRecord
  has_many :turmas
  has_many :ano_letivos, dependent: :destroy
  has_many :alunos, through: :turmas
  has_one  :endereco, dependent: :destroy

  accepts_nested_attributes_for :endereco, allow_destroy: true

  validates :nome, presence: true, uniqueness: true
  validates :cnpj, uniqueness: true, format: { with: /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/, message: "deve estar no formato XX.XXX.XXX/XXXX-XX" }

  scope :mais_alunos, -> { order(alunos_count: :desc) }
  scope :menos_alunos, -> { order(alunos_count: :asc) }

  scope :mais_turmas, -> { order(turmas_count: :desc) }
  scope :menos_turmas, -> { order(turmas_count: :asc) }
end
