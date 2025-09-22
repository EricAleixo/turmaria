class Admin < ApplicationRecord
  # Relacionamentos
  has_many :escolas, dependent: :nullify

  include EmailCadastroUser
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
end
