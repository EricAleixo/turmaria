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
  has_many :frequencias, dependent: :destroy
  has_many :conteudos, dependent: :destroy

  accepts_nested_attributes_for :endereco

  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestrado: "mestrado", doutorado: "doutorado", pos_graduado:"pos_graduado", graduado:"graduado" }

  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true

  # Busca por nome
  scope :por_nome, ->(busca) { where("nome ILIKE ?", "%#{busca}%") if busca.present? }

  # Filtro por formação
  scope :por_formacao, ->(formacao) { where(formacao: formacao) if formacao.present? }

  # Filtro por tipo (concursado, contratado etc)
  scope :por_tipo, ->(tipo) { where(tipo_professor: tipo) if tipo.present? }



  def endereco_completo
    return "Endereço não cadastrado" unless endereco.present?
    
    parts = []
    parts << "#{endereco.logradouro}, #{endereco.numero}" if endereco.logradouro.present? && endereco.numero.present?
    parts << endereco.complemento if endereco.complemento.present?
    parts << endereco.bairro if endereco.bairro.present?
    if endereco.cidade.present?
      parts << "#{endereco.cidade.nome} - #{endereco.cidade.estado.nome}"
    end
    parts << "CEP: #{endereco.cep}" if endereco.cep.present?
    
    parts.join(', ')
  end

end
