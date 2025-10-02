class Professor < ApplicationRecord

  include EmailCadastroUser
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
 
  belongs_to :escola, optional: true
  belongs_to :coordenador, optional: true
  has_many :professor_turmas
  has_many :turmas, through: :professor_turmas
  has_one :endereco, dependent: :destroy
  has_many :alunos, through: :turmas
  has_many :professor_disciplinas
  has_many :disciplinas, through: :professor_disciplinas

  accepts_nested_attributes_for :endereco

  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestrado: "mestrado", doutorado: "doutorado", pos_graduado:"pos_graduado", graduado:"graduado" }

  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true

 def endereco_completo
  return "Endereço não cadastrado" unless endereco.present?

  partes = []
  partes << "#{endereco.logradouro}, #{endereco.numero}" if endereco.logradouro.present? && endereco.numero.present?
  partes << endereco.complemento if endereco.complemento.present?
  partes << endereco.bairro if endereco.bairro.present?
  if endereco.cidade.present?
    partes << "#{endereco.cidade.nome} - #{endereco.cidade.estado.nome}"
  end
  partes << "CEP: #{endereco.cep}" if endereco.cep.present?

  partes.join(', ')
  end
end 
