class SuperAdmin < ApplicationRecord
  # === Active Storage ===
  has_one_attached :foto
  
  # === Includes ===
  include EmailCadastroUser
  
  # === Devise ===
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
  
  # === Validações ===
  validate :foto_format_and_size, if: -> { foto.attached? && foto.blob.present? }
  
  # === Callbacks ===
  # Remove a foto antiga do S3 antes de anexar uma nova
  before_save :purge_old_foto, if: -> { foto.attached? && foto_attachment_changed? }
  
  # Remove a foto do S3 quando o super admin for excluído
  before_destroy :purge_foto_on_destroy
  
  private
  
  # Validação de formato e tamanho da foto
  def foto_format_and_size
    if foto.blob.byte_size > 2.megabytes
      errors.add(:foto, "deve ter no máximo 2MB")
    end
    
    acceptable_types = ["image/jpeg", "image/png"]
    unless acceptable_types.include?(foto.blob.content_type)
      errors.add(:foto, "deve ser JPG ou PNG")
    end
  end
  
  # Remove a foto antiga do S3 quando uma nova foto é anexada
  def purge_old_foto
    return unless foto.attached?
    
    # Verifica se existe uma foto antiga anexada
    old_foto = foto.attachment
    
    # Se houver mudança no attachment (nova foto sendo enviada)
    if old_foto && foto.changed?
      # Agenda a remoção da foto antiga do S3
      old_foto.purge_later
    end
  end
  
  # Método auxiliar para verificar se o attachment mudou
  def foto_attachment_changed?
    foto.changed?
  end
  
  # Remove a foto do S3 quando o super admin for excluído do banco
  def purge_foto_on_destroy
    foto.purge_later if foto.attached?
  end
end