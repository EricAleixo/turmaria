class Escola < ApplicationRecord
  # Relacionamentos
  has_many :turmas
  has_many :ano_letivos, dependent: :destroy
  has_many :alunos, through: :turmas
  has_one  :endereco, dependent: :destroy
  has_many :admins, dependent: :nullify
  belongs_to :admin, optional: true
  has_many :materias
  has_many :disciplinas
  has_many :professors

  accepts_nested_attributes_for :endereco, allow_destroy: true

  # Validações
  validates :nome, presence: true, uniqueness: true
  validates :cnpj, uniqueness: true, format: { with: /\A\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}\z/, message: "deve estar no formato XX.XXX.XXX/XXXX-XX" }, allow_blank: true
  validates :tipo, presence: true, inclusion: { in: %w[publica privada], message: "deve ser pública ou privada" }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  # Enums
  enum tipo: { publica: 'publica', privada: 'privada' }

  # Scopes
  scope :mais_alunos, -> { order(alunos_count: :desc) }
  scope :menos_alunos, -> { order(alunos_count: :asc) }
  scope :mais_turmas, -> { order(turmas_count: :desc) }
  scope :menos_turmas, -> { order(turmas_count: :asc) }
  scope :publicas, -> { where(tipo: 'publica') }
  scope :privadas, -> { where(tipo: 'privada') }

  # Métodos
  def tipo_humanizado
    case tipo
    when 'publica'
      'Pública'
    when 'privada'
      'Privada'
    end
  end

  def endereco_completo
    return "Endereço não cadastrado" unless endereco.present?
    
    partes = []
    partes << "#{endereco.logradouro}, #{endereco.numero}" if endereco.logradouro.present? && endereco.numero.present?
    partes << endereco.complemento if endereco.complemento.present?
    partes << endereco.bairro if endereco.bairro.present?
    partes << "#{endereco.cidade.nome} - #{endereco.cidade.estado.nome}" if endereco.cidade.present?
    partes << "CEP: #{endereco.cep}" if endereco.cep.present?
    
    partes.join(', ')
  end
end
