class Aluno < ApplicationRecord

  has_many :registros_de_notas
  has_many :avaliacoes_bimestrais
  has_many :frequencia_alunos, dependent: :nullify
  has_one_attached :foto
  has_many_attached :cpf_documento
  has_one_attached :comprovante_residencia
  has_one_attached :historico_academico
  has_one :endereco, dependent: :destroy 

  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable,
       authentication_keys: [:matricula]

  belongs_to :escola, counter_cache: :alunos_count
  belongs_to :turma, optional: true
  belongs_to :cidade, optional: true
  has_one :user, as: :profile, dependent: :destroy
 
  # Validações:
  # Apenas 'nome' é obrigatório para a criação do aluno.
  # A matricula não é obrigatória na criação, pois será gerada automaticamente.
  validates :nome, presence: true

  # A validação de unicidade da matrícula ainda é necessária,
  # mas a presença é verificada apenas quando o campo não está vazio.
  validates :matricula, uniqueness: true, allow_blank: true

  # Esta validação sobrescreve a validação padrão do Devise,
  # permitindo que o campo 'email' possa ser nulo ou vazio.
  validates :email, allow_blank: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "formato incorreto" }

  # As outras validações de formato continuam, mas agora permitem
  # que os campos fiquem em branco.
  validates :cpf, format: { with: /\A\d{3}\.\d{3}\.\d{3}-\d{2}\z/, message: "formato incorreto (ex: 000.000.000-00)" }, allow_blank: true
  validates :telefone, format: { with: /\A\(\d{2}\)\s?\d{4,5}-\d{4}\z/, message: "formato incorreto (ex: (00) 00000-0000)" }, allow_blank: true

  validate :turma_belongs_to_same_escola, if: :turma_id?

  accepts_nested_attributes_for :user, allow_destroy: true

  # >>> AQUI ESTÁ O NOVO CÓDIGO <<<
  # Callback que gera a matrícula automaticamente se ela não estiver presente
  before_validation :generate_matricula, on: :create
  
  def generate_matricula
    # Exemplo: Uma string que combina o ID da escola e um timestamp.
    # Isso garante que a matrícula seja única.
    if self.matricula.blank?
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      self.matricula = "ESC-#{escola.id}-#{timestamp}"
    end
  end
  # >>> FIM DO NOVO CÓDIGO <<<

  scope :allocated, -> { where.not(turma_id: nil) }
  scope :unallocated, -> { where(turma_id: nil) }
  scope :by_escola, ->(escola_id) { where(escola_id: escola_id) }

  def display_name
    nome
  end

  def allocated?
    turma_id.present?
  end

  def unallocated?
    !allocated?
  end

  def status
    allocated? ? "Alocado - #{turma.nome}" : "Não alocado"
  end

  def idade
    return nil unless data_nascimento
    
    hoje = Date.current
    idade_calculada = hoje.year - data_nascimento.year
    
    # Ajusta se ainda não fez aniversário este ano
    if hoje.month < data_nascimento.month || 
      (hoje.month == data_nascimento.month && hoje.day < data_nascimento.day)
      idade_calculada -= 1
    end
    
    idade_calculada
  end

  before_create :set_idade_on_create

  private

  def turma_belongs_to_same_escola
    return unless turma_id && escola_id
    
    unless turma.escola_id == escola_id
      errors.add(:turma, "deve pertencer à mesma escola do aluno")
    end
  end

  def set_idade_on_create
    if data_nascimento.present?
      hoje = Date.current
      idade_calculada = hoje.year - data_nascimento.year
      
      # Ajusta se ainda não fez aniversário este ano
      if hoje.month < data_nascimento.month || 
        (hoje.month == data_nascimento.month && hoje.day < data_nascimento.day)
        idade_calculada -= 1
      end
      
      self.idade = idade_calculada
    end
  end
end 