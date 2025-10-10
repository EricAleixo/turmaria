class Disciplina < ApplicationRecord

  has_many :turma_disciplinas
  has_many :turmas, through: :turma_disciplinas

  has_many :avaliacoes_configuracoes
  has_many :avaliacoes_bimestrais

  has_many :professor_disciplinas
  has_many :professores, through: :professor_disciplinas, source: :professor
  enum area: {
    exatas: "exatas",
    humanas: "humanas",
    linguagens: "linguagens",
    biologicas: "biologicas",
    tecnica: "tecnica",
    interdisciplinares: "interdisciplinares",
    extras: "extras"
  }

  belongs_to :escola
end
  