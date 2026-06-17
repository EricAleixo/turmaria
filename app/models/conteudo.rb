class Conteudo < ApplicationRecord
  belongs_to :turma
  belongs_to :professor, optional: true
  belongs_to :disciplina
  belongs_to :escola, optional: true

  has_many_attached :materiais

  enum tipo: { material: 0, atividade: 1 }

  validates :titulo, presence: true

  validates :bimestre, presence: true,
                       numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :tipo, presence: true

  validate :materiais_tipo_valido

  validate :disciplina_deve_pertencer_a_turma

  private

  def disciplina_deve_pertencer_a_turma
    return if turma.nil? || disciplina.nil?

    unless turma.disciplinas.exists?(disciplina.id)
      errors.add(:disciplina_id, "não pertence à turma selecionada")
    end
  end

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
