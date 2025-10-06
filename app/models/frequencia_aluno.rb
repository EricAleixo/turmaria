class FrequenciaAluno < ApplicationRecord
  belongs_to :frequencia
  belongs_to :aluno

  enum status: { presente: 'presente', falta: 'falta', justificada: 'justificada' }

  validates :frequencia_id, uniqueness: { scope: :aluno_id, message: "Aluno já possui registro de frequência para esta aula" }
  validate :aluno_deve_pertencer_a_turma

  scope :presentes, -> { where(status: 'presente') }
  scope :faltas, -> { where(status: 'falta') }
  scope :justificadas, -> { where(status: 'justificada') }

  def status_humanizado
    case status
    when 'presente'
      'Presente'
    when 'falta'
      'Falta'
    when 'justificada'
      'Justificada'
    end
  end

  def status_cor
    case status
    when 'presente'
      'text-green-600 bg-green-100'
    when 'falta'
      'text-red-600 bg-red-100'
    when 'justificada'
      'text-yellow-600 bg-yellow-100'
    end
  end

  private

  def aluno_deve_pertencer_a_turma
    return unless aluno.present? && frequencia.present? && frequencia.turma.present?
    
    unless aluno.turma_id == frequencia.turma_id
      errors.add(:base, "Aluno não pertence à turma desta frequência")
    end
  end
end
