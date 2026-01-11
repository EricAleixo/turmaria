class Disciplina < ApplicationRecord
  # Associações
  has_many :turma_disciplinas
  has_many :turmas, through: :turma_disciplinas
  has_many :avaliacoes_configuracoes, 
           class_name: 'AvaliacaoConfiguracao', 
           foreign_key: 'disciplina_id'
  has_many :avaliacoes_bimestrais
  has_many :professor_disciplinas
  has_many :professores, through: :professor_disciplinas, source: :professor
  belongs_to :escola
  belongs_to :area_disciplina
  has_many :conteudos, dependent: :destroy

  # Validações
  validates :nome, presence: { message: "não pode ficar em branco" }
  validates :escola_id, presence: { message: "deve ser selecionada" }
  validates :area_disciplina_id, presence: { message: "deve ser selecionada" }
  
  # Valida que a área pertence à mesma escola
  validate :area_disciplina_pertence_a_escola

  private

  def area_disciplina_pertence_a_escola
    return if area_disciplina_id.blank? || escola_id.blank?
    
    unless area_disciplina&.escola_id == escola_id
      errors.add(:area_disciplina_id, "deve pertencer à mesma escola")
    end
  end
end