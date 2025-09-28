class Professor < ApplicationRecord

  include EmailCadastroUser
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  belongs_to :escola
  has_many :professor_turmas
  has_many :turmas, through: :professor_turmas
  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestado: "mestrado", doutorado: "doutorado", pos_graduado:"pos_graduado", graduado:"graduado" }
  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true
end
