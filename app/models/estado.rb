class Estado < ApplicationRecord
  has_many :cidades

  validates :nome, presence: true, uniqueness: true
end