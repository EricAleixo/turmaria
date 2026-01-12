class Professor < ApplicationRecord
  # === Active Storage ===
  has_one_attached :foto

  # === Includes ===
  include EmailCadastroUser

  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # === Associações ===
  belongs_to :escola, optional: true
  belongs_to :coordenador, class_name: 'Professor', foreign_key: 'coordenador_id', optional: true
  
  has_many :professor_turmas, dependent: :destroy
  has_many :turmas, through: :professor_turmas
  has_one :endereco, dependent: :destroy
  has_many :alunos, through: :turmas
  has_many :professor_disciplinas, dependent: :destroy
  has_many :disciplinas, through: :professor_disciplinas
  has_many :frequencias, dependent: :nullify
  has_many :conteudos, dependent: :nullify
  
  accepts_nested_attributes_for :endereco

  # === Enums ===
  enum tipo_professor: { concursado: "concursado", contratado: "contratado" }
  enum formacao: { mestrado: "mestrado", doutorado: "doutorado", pos_graduado: "pos_graduado", graduado: "graduado" }

  # === Validações ===
  validates :nome, :cpf, presence: true
  validates :cpf, uniqueness: true
  validate :foto_format_and_size, if: -> { foto.attached? && foto.blob.present? }

  
  # Remove a foto do S3 ao destruir o registro
  before_destroy :purge_foto_on_destroy

  # === Validação de formato e tamanho ===
  def foto_format_and_size
    if foto.blob.byte_size > 2.megabytes
      errors.add(:foto, "deve ter no máximo 2MB")
    end

    acceptable_types = ["image/jpeg", "image/png"]
    unless acceptable_types.include?(foto.blob.content_type)
      errors.add(:foto, "deve ser JPG ou PNG")
    end
  end

  private

  # Remove a foto do S3 ao destruir o registro
  def purge_foto_on_destroy
    foto.purge_later if foto.attached?
  end
end