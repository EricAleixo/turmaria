class Endereco < ApplicationRecord
  belongs_to :cidade, optional: true
  belongs_to :aluno, optional: true
  belongs_to :escola, optional: true
  belongs_to :professor, optional:true
end