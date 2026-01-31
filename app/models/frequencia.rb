class Frequencia < ApplicationRecord
  self.table_name = 'frequencias'
  
  # Associações
  belongs_to :turma
  belongs_to :professor
  belongs_to :disciplina
  has_many :frequencia_alunos, dependent: :destroy
  has_many :alunos, through: :frequencia_alunos
  
  # Validações
  validates :data_aula, presence: { message: "deve ser informada" }
  validates :disciplina_id, presence: { message: "deve ser selecionada" }
  validates :turma_id, presence: true
  validates :professor_id, presence: true
  
  validates :turma_id, uniqueness: { 
    scope: [:data_aula, :disciplina_id], 
    message: "Já existe frequência registrada para esta turma, disciplina e data" 
  }
  
  # Validações customizadas
  validate :data_aula_nao_pode_ser_futura
  validate :professor_deve_lecionar_na_turma
  validate :disciplina_pertence_a_turma
  
  # Scopes
  scope :por_data, -> { order(data_aula: :desc) }
  scope :por_turma, ->(turma_id) { where(turma_id: turma_id) }
  scope :da_escola, ->(escola_id) { 
    joins(:turma).where(turmas: { escola_id: escola_id })
  }
  
  # Métodos de contagem
  def total_alunos
    frequencia_alunos.count
  end
  
  def total_presentes
    frequencia_alunos.where(status: 'presente').count
  end
  
  def total_faltas
    frequencia_alunos.where(status: 'falta').count
  end
  
  def total_justificadas
    frequencia_alunos.where(status: 'justificada').count
  end
  
  def percentual_presenca
    return 0 if total_alunos.zero?
    ((total_presentes.to_f / total_alunos) * 100).round(1)
  end
  
  private
  
  def data_aula_nao_pode_ser_futura
    return unless data_aula.present?
    
    if data_aula > Date.current
      errors.add(:data_aula, "não pode ser uma data futura")
    end
  end
  
  def professor_deve_lecionar_na_turma
    return unless professor.present? && turma.present?
    
    unless professor.turmas.include?(turma)
      errors.add(:base, "Professor não leciona nesta turma")
    end
  end
  
  def disciplina_pertence_a_turma
    return if disciplina_id.blank? || turma_id.blank?
    
    unless turma.disciplinas.exists?(disciplina_id)
      errors.add(:disciplina_id, "não está associada a esta turma")
    end
  end
end