class Turma < ApplicationRecord
  enum turno: {manha:0, tarde:1, noite:2, integral:3 }

  belongs_to :escola
  has_many :alunos
end
