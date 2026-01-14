class Aluno < ApplicationRecord
  devise :database_authenticatable,
         :rememberable,
         :validatable

  # === Associações ===
  belongs_to :escola
  belongs_to :turma, optional: true
  belongs_to :cidade, optional: true
  
  has_many :avaliacoes_bimestrais,
           class_name: 'AvaliacaoBimestral',
           dependent: :destroy
  
  has_many :turmas_cursadas,
           -> { distinct },
           through: :avaliacoes_bimestrais,
           source: :turma,
           class_name: 'Turma'
  
  has_many :anos_letivos_com_boletim,
           -> { distinct },
           through: :turmas_cursadas,
           source: :ano_letivo,
           class_name: 'AnoLetivo'
  
  has_many :registros_de_notas,
           class_name: 'RegistroDeNota',
           dependent: :destroy
  
  has_many :avaliacoes_configuracoes,
           through: :registros_de_notas

  # === Active Storage ===
  has_one_attached :foto
  has_one_attached :historico_academico
  has_many_attached :cpf_documento
  has_many_attached :comprovante_residencia

  # === Validações ===
  validates :nome,
            presence: { message: "não pode estar em branco." },
            length: { minimum: 3 }
  
  validates :cpf,
            uniqueness: { allow_blank: true, message: "já está em uso." }
  
  validates :matricula,
            presence: true,
            uniqueness: true
  
  validates :password,
            length: { minimum: 6 },
            if: :password_required?
  
  validates :email,
            uniqueness: { case_sensitive: false },
            allow_blank: true

  # === Callbacks ===
  before_validation :generate_matricula, on: :create
  before_validation :set_default_email, on: :create
  before_validation :set_default_password, on: :create
  
  # CORRIGIDO: Remove arquivos antigos do S3 apenas quando necessário
  before_save :purge_old_attachments_if_changed
  
  # Remove todos os arquivos do S3 quando o aluno for excluído
  before_destroy :purge_all_attachments

  def self.authentication_keys
    [:matricula]
  end

  def idade
    return nil unless data_nascimento
    
    hoje = Date.current
    idade = hoje.year - data_nascimento.year
    idade -= 1 if hoje < data_nascimento + idade.years
    idade
  end

  def status_aluno
    turma_id.present? ? "Alocado" : "Pendente de Alocação"
  end

  def anos_letivos_com_notas
    anos_letivos_com_boletim.order(ano: :desc)
  end

  # === Scopes ===
  scope :busca_geral, ->(termo) do
    if termo.present?
      busca = "%#{termo.downcase}%"
      where("LOWER(alunos.nome) LIKE :b OR LOWER(alunos.matricula) LIKE :b", b: busca)
    else
      all
    end
  end

  scope :busca_por_nome_turma, ->(termo) do
    if termo.present?
      busca = "%#{termo.downcase}%"
      left_outer_joins(:turma).where("LOWER(turmas.nome) LIKE ?", busca)
    else
      all
    end
  end

  scope :por_escola, ->(escola_id) { where(escola_id: escola_id) if escola_id.present? }
  scope :por_cidade, ->(cidade_id) { where(cidade_id: cidade_id) if cidade_id.present? }
  
  scope :por_estado, ->(uf) do
    if uf.present?
      left_outer_joins(:cidade).where("cidades.uf = ?", uf.upcase)
    else
      all
    end
  end

  scope :por_status_alocacao, ->(status) do
    case status.to_s.downcase
    when 'alocado'
      where.not(turma_id: nil)
    when 'nao_alocado'
      where(turma_id: nil)
    else
      all
    end
  end

  scope :maiores_de_18, -> { where("data_nascimento <= ?", 18.years.ago.to_date) }
  scope :menores_de_18, -> { where("data_nascimento > ?", 18.years.ago.to_date) }

  def email_required?
    false
  end

  def password_required?
    new_record? || password.present?
  end

  # =========================================================
  # 🔒 MÉTODOS PRIVADOS
  # =========================================================
  private

  def set_default_email
    self.email = "aluno_#{SecureRandom.hex(4)}@temporario.com" if email.blank?
  end

  def set_default_password
    return if password.present?
    
    senha = SecureRandom.hex(8)
    self.password = senha
    self.password_confirmation = senha
  end

  def generate_matricula
    return if matricula.present?
    
    loop do
      self.matricula = SecureRandom.alphanumeric(8).upcase
      break unless Aluno.exists?(matricula: matricula)
    end
  end

  # === CORRIGIDO: Método único para limpar attachments antigos ===
  def purge_old_attachments_if_changed
    # Foto (has_one_attached)
    if foto.attached? && will_save_change_to_attribute?(:foto)
      old_blob_id = foto.blob_id
      if old_blob_id && foto.blob_id != old_blob_id
        ActiveStorage::Blob.find_by(id: old_blob_id)&.purge_later
      end
    end

    # Histórico (has_one_attached)
    if historico_academico.attached? && will_save_change_to_attribute?(:historico_academico)
      old_blob_id = historico_academico.blob_id
      if old_blob_id && historico_academico.blob_id != old_blob_id
        ActiveStorage::Blob.find_by(id: old_blob_id)&.purge_later
      end
    end

    # CPF Documentos (has_many_attached)
    purge_detached_blobs_for(:cpf_documento)

    # Comprovantes (has_many_attached)
    purge_detached_blobs_for(:comprovante_residencia)
  end

  # Remove blobs que não estão mais anexados (para has_many_attached)
  def purge_detached_blobs_for(attachment_name)
    return unless send(attachment_name).attached?

    current_blob_ids = send(attachment_name).blobs.pluck(:id)
    
    # Busca blobs anteriormente anexados
    old_blob_ids =
                  send(attachment_name).attachments
                    .map(&:blob_id)
                    .compact
                    .reject { |id| current_blob_ids.include?(id) }

    old_blob_ids.each do |blob_id|
      ActiveStorage::Blob.find(blob_id).purge
    end
  end

  # Remove TODOS os arquivos do S3 quando o aluno for excluído
  def purge_all_attachments
    foto.purge_later if foto.attached?
    historico_academico.purge_later if historico_academico.attached?
    cpf_documento.purge_later if cpf_documento.attached?
    comprovante_residencia.purge_later if comprovante_residencia.attached?
  end
end