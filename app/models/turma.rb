class Turma < ApplicationRecord
  enum turno: {manha:0, tarde:1, noite:2, integral:3 }

  belongs_to :ano_letivo
  belongs_to :escola, counter_cache: true
  has_many :alunos
  
  has_many :professor_turmas
  has_many :professores, through: :professor_turmas

  validates :nome, presence: true
  validates :serie, presence: true
end
