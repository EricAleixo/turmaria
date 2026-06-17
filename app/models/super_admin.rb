class SuperAdmin < ApplicationRecord
  # === Active Storage ===
  has_one_attached :foto

  # === Includes ===
  include EmailCadastroUser

  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  # === Validações ===
  validate :foto_format_and_size, if: -> { foto.attached? && foto.blob.present? }

  # === Callbacks ===
  # Remove a foto antiga se houver troca
  before_update :purge_old_foto, if: :foto_being_replaced?

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

  # Verifica se há uma foto nova anexada substituindo a antiga
  def foto_being_replaced?
    return false unless foto.attached?

    old_attachment = ActiveStorage::Attachment.find_by(record: self, name: "foto")
    old_attachment.present? && old_attachment.id != foto.attachment&.id
  end

  # Purga a foto antiga do S3
  def purge_old_foto
    old_attachment = ActiveStorage::Attachment.find_by(record: self, name: "foto")
    old_attachment.purge if old_attachment
  end

  # Remove a foto do S3 ao destruir o registro
  def purge_foto_on_destroy
    foto.purge if foto.attached?
  end
end
