class Conteudo < ApplicationRecord
  belongs_to :professor, optional:true 
  belongs_to :disciplina, optional:true 
  belongs_to :escola, optional: true
  
  has_many_attached :materiais
  
  validate :materiais_tipo_valido

  private
  
  def materiais_tipo_valido

    return unless materiais.attached?

    formatos_permitidos = %w[
    application/pdf
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    image/jpeg
    image/png
    ]


    materiais.each do |arquivo|
      unless arquivo.content_type.in?(formatos_permitidos)
        errors.add(:materiais, "deve ser PDF ou DOCX")
      end
    end
  end
end
