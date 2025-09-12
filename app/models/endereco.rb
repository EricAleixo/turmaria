class Endereco < ApplicationRecord
  belongs_to :aluno, optional: true
  belongs_to :escola, optional: true
end