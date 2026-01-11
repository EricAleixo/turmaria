class AreaDisciplina < ApplicationRecord
  belongs_to :escola
  has_many :disciplinas, dependent: :restrict_with_error
end
