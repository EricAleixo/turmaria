class EmailCadastro < ApplicationRecord
  validates :email, presence: true, uniqueness: true
end
