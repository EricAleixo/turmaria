class AreaDisciplina < ApplicationRecord
  belongs_to :escola
  has_many :disciplinas, dependent: :destroy
end
