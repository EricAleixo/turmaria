class AnoLetivo < ApplicationRecord
  has_many :turmas, dependent: :destroy
  accepts_nested_attributes_for :turmas
  belongs_to :escola

  validates :ano, presence: true, uniqueness: true, length: {maximum: 4}
  validates :data_inicio, presence: true, length: {maximum: 11}
  validates :data_fim, presence: true, length: {maximum: 11}
end
