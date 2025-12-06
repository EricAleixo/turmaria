# app/models/aluno.rb

class Aluno < ApplicationRecord
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :trackable

  # === Associações ===
  belongs_to :escola
  belongs_to :turma, optional: true
  belongs_to :cidade, optional: true

  
  # === Associações ===
  # 1. Aluno tem muitas Avaliações Bimestrais
  has_many :avaliacoes_bimestrais, dependent: :destroy, class_name: 'AvaliacaoBimestral'
  
  # 2. Aluno tem muitas Turmas ao longo do tempo (através das notas)
  # CORRIGIDO: Removendo o 'distinct: true' do options hash e usando o bloco de escopo.
  has_many :turmas_cursadas, -> { distinct }, 
           through: :avaliacoes_bimestrais, 
           source: :turma, 
           class_name: 'Turma'
  
  # 3. Aluno tem muitos Anos Letivos (através das turmas cursadas)
  # CORRIGIDO: Removendo o 'distinct: true' do options hash e usando o bloco de escopo.
  has_many :anos_letivos_com_boletim, -> { distinct }, 
           through: :turmas_cursadas, 
           source: :ano_letivo, 
           class_name: 'AnoLetivo'


  # === Validações ===
  validates :nome, presence: { message: "não pode estar em branco." }, length: { minimum: 3 }
  validates :cpf, uniqueness: { allow_blank: true, message: "já está em uso." }
  validates :matricula, uniqueness: true, allow_nil: true
  validates :email, allow_blank: true, uniqueness: { case_sensitive: false, allow_blank: true }

  # === Active Storage ===
  has_one_attached :foto
  has_one_attached :historico_academico
  has_many_attached :cpf_documento
  has_many_attached :comprovante_residencia

  # === Callbacks ===
  before_validation :set_default_email, on: :create
  before_validation :set_default_password, on: :create
  before_create :generate_matricula

  # === Métodos Públicos ===

  def anos_letivos_com_notas
    # Retorna uma coleção de objetos AnoLetivo, ordenados do mais novo para o mais antigo.
    anos_letivos_com_boletim.order(ano: :desc)
  end
  
  def idade
    return nil unless data_nascimento
    today = Date.current
    age = today.year - data_nascimento.year
    age -= 1 if today < data_nascimento + age.years
    age
  end
  
  def status_aluno
    if turma_id.present?
      "Alocado"
    else
      "Pendente de Alocação"
    end
  end
  
  def email_required?
    false
  end

  def password_required?
    false
  end

  private

  def set_default_email
    self.email = "aluno_#{SecureRandom.hex(4)}@temporario.com" if email.blank?
  end

  def set_default_password
    if password.blank?
      self.password = SecureRandom.hex(8)
      self.password_confirmation = self.password
    end
  end

  def generate_matricula
    return if matricula.present?
    
    loop do
      self.matricula = SecureRandom.alphanumeric(8).upcase
      break unless Aluno.exists?(matricula: matricula)
    end
  end
end