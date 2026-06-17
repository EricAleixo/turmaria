class Estado < ApplicationRecord
  has_many :cidades, dependent: :destroy

  validates :nome, presence: true, uniqueness: true
end