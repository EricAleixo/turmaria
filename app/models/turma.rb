class Turma < ApplicationRecord
  enum turno: { manha: 0, tarde: 1, noite: 2, integral: 3 }

  belongs_to :ano_letivo
  belongs_to :escola, counter_cache: true

  has_many :alunos

  has_many :professor_turmas, dependent: :destroy
  has_many :professores,
           through: :professor_turmas,
           source: :professor

  has_many :turma_disciplinas
  has_many :disciplinas, through: :turma_disciplinas

  has_many :conteudos, dependent: :destroy   # 👈 AQUI

  has_many :frequencias, dependent: :destroy
  has_many :avaliacoes_configuracoes, class_name: 'AvaliacaoConfiguracao'
  has_many :avaliacoes_bimestrais,
           class_name: 'AvaliacaoBimestral',
           dependent: :destroy

  validates :nome, presence: true
  validates :serie, presence: true
  validate :ano_letivo_deve_pertencer_a_escola

  def turno_humanizado
    self.class.human_attribute_name("turnos.#{turno}")
  end

  def nome_completo
    "#{nome} - #{escola.nome} (#{serie}º #{turno.humanize})"
  end

  def bimestres_disponiveis
    num_max = ano_letivo&.numero_bimestre || 4
    (1..num_max).to_a
  end

  private

  def ano_letivo_deve_pertencer_a_escola
    return unless ano_letivo.present? && escola.present?

    if ano_letivo.escola_id != escola.id
      errors.add(:base, "O Ano Letivo selecionado não pertence a esta Escola.")
    end
  end
end
