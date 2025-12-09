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
  
  # === Métodos de Instância ===
  def generate_matricula
    loop do
      year = Time.zone.now.year
      random_sequence = SecureRandom.hex(4).upcase
      candidate = "ESC-#{escola_id}-#{year}-#{random_sequence}"
      self.matricula = candidate
      break unless Aluno.exists?(matricula: candidate)
    end
  end

  def idade
    return nil unless data_nascimento
    today = Date.current
    age = today.year - data_nascimento.year
    age -= 1 if today < data_nascimento + age.years
    age
  end
  
  # =========================================================================
  # O MÉTODO QUE ESTAVA FALTANDO PARA RESOLVER O NoMethodError
  # =========================================================================
  # Este método é chamado na view (aluno.status_aluno) e no controller (para filtros).
  def status_aluno
    if turma_id.present?
      "Alocado"
    else
      "Pendente de Alocação"
    end
  end

  # =========================================================================
  # 🎯 SCOPES (Filtros do Active Record)
  # =========================================================================

  # 1. Busca Geral (Caixa de Texto: Nome OU Matrícula)
  scope :busca_geral, ->(termo) do
    if termo.present?
      busca_param = "%#{termo.downcase}%"
      where("LOWER(alunos.nome) LIKE :busca OR LOWER(alunos.matricula) LIKE :busca" , busca: busca_param)
    else
      all
    end
  end

  # 2. Busca por Nome da Turma (Caixa de Texto específica)
  scope :busca_por_nome_turma, ->(termo) do
    if termo.present?
      busca_param = "%#{termo.downcase}%"
      # Usa LEFT OUTER JOINs para buscar na tabela turmas
      left_outer_joins(:turma).where("LOWER(turmas.nome) LIKE ?", busca_param)
    else
      all 
    end
  end
  
  # 3. Filtro por Escola (ID)
  scope :por_escola, ->(escola_id) { where(escola_id: escola_id) if escola_id.present? }

  # 4. Filtro por Cidade (ID)
  scope :por_cidade, ->(cidade_id) { where(cidade_id: cidade_id) if cidade_id.present? }

  # 5. Filtro por Estado (Sigla UF)
  scope :por_estado, ->(uf_sigla) do
    if uf_sigla.present?
      # LEFT OUTER JOINs é necessário para filtrar pelo UF da Cidade
      left_outer_joins(:cidade).where("cidades.uf = ?", uf_sigla.upcase)
    else
      all
    end
  end

  # 6. Filtro por Status de Alocação (Checkbox: Alocado/Não Alocado)
  scope :por_status_alocacao, ->(status) do
    case status.to_s.downcase
    when 'alocado'
      where.not(turma_id: nil) # O aluno possui um turma_id
    when 'nao_alocado' # Usaremos 'nao_alocado' como parâmetro no Controller
      where(turma_id: nil)     # O aluno NÃO possui um turma_id
    else
      all
    end
  end

  # 7. Filtro por Idade: Maiores de 18 Anos (Checkbox)
  scope :maiores_de_18, -> { where("data_nascimento <= ?", 18.years.ago.to_date) }

  # 8. Filtro por Idade: Menores de 18 Anos (Checkbox)
  scope :menores_de_18, -> { where("data_nascimento > ?", 18.years.ago.to_date) }
  
  
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