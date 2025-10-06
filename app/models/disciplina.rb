class Disciplina < ApplicationRecord
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
  