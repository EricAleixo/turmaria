class Escola < ApplicationRecord
   has_many :turmas, dependent: :destroy
end
