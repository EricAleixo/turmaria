class Disciplina < ApplicationRecord

  has_many :turma_disciplinas
  has_many :turmas, through: :turma_disciplinas

  has_many :avaliacoes_configuracoes
  has_many :avaliacoes_bimestrais

  has_many :professor_disciplinas
  has_many :professores, through: :professor_disciplinas, source: :professor
  belongs_to :escola
end
  