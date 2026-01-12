# app/models/admin.rb
class Admin < ApplicationRecord
  # === Active Storage ===
  has_one_attached :foto
  
  # === Includes ===
  include EmailCadastroUser
  
  # === Devise ===
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable
  
  # === Relacionamentos ===
  has_many :escolas, dependent: :nullify
  
  # === Validações ===
  validate :foto_format_and_size, if: -> { foto.attached? && foto.blob.present? }
  
  private
  
  # Validação de formato e tamanho da foto
  def foto_format_and_size
    return unless foto.attached? && foto.blob.present?
    
    # Valida o tamanho
    if foto.blob.byte_size > 5.megabytes
      errors.add(:foto, "deve ter no máximo 5MB")
    end
    
    # Valida o tipo
    acceptable_types = ["image/jpeg", "image/jpg", "image/png", "image/gif"]
    unless acceptable_types.include?(foto.blob.content_type)
      errors.add(:foto, "deve ser JPG, PNG ou GIF")
    end
  end
end