class Escola < ApplicationRecord
  has_many :turmas, dependent: :destroy
  has_many :alunos, through: :turmas

  validates :nome, presence: true, uniqueness: true
  validates :cnpj, presence: true, uniqueness: true, format: { with: /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/, message: "deve estar no formato XX.XXX.XXX/XXXX-XX" }
end
