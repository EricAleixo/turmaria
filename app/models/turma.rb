class Turma < ApplicationRecord
  enum turno: {manha:0, tarde:1, noite:2, integral:3 }

  belongs_to :ano_letivo
  belongs_to :escola, counter_cache: true
  has_many :alunos

  validates :nome, presence: true
  validates :serie, presence: true
end
