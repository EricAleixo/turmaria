class Admin < ApplicationRecord
  # Relacionamentos
  has_many :escolas, dependent: :nullify
  has_one_attached :foto
  validate :foto_format_and_size, if: -> { foto.attached? && foto.blob.present? }

  include EmailCadastroUser
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable

  private

  def foto_format_and_size
    if foto.blob.byte_size > 2.megabytes
      errors.add(:foto, "deve ter no máximo 2MB")
    end

    acceptable_types = ["image/jpeg", "image/png", "image/gif"]
    unless acceptable_types.include?(foto.blob.content_type)
      errors.add(:foto, "deve ser JPG, PNG ou GIF")
    end
  end
end
