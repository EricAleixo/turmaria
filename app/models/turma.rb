class Turma < ApplicationRecord
  enum turno: { manha: 0, tarde: 1, noite: 2, integral: 3 }
  enum :tipo_avaliacao, { nota: 0, conceito: 1 }, prefix: :avaliacao

  belongs_to :ano_letivo
  belongs_to :escola, counter_cache: true

  before_destroy :verificar_alunos_vinculados

  has_many :alunos
  has_many :professor_turmas, dependent: :destroy
  has_many :professores, through: :professor_turmas, source: :professor
  has_many :turma_disciplinas
  has_many :disciplinas, through: :turma_disciplinas
  has_many :conteudos, dependent: :destroy
  has_many :frequencias, dependent: :destroy
  has_many :avaliacoes_configuracoes, class_name: 'AvaliacaoConfiguracao'
  has_many :avaliacoes_bimestrais, class_name: 'AvaliacaoBimestral', dependent: :destroy

  validates :nome, presence: true
  validates :serie, presence: true
  validates :turno, presence: true, inclusion: { in: turnos.keys }
  validates :tipo_avaliacao, presence: true

  validate :ano_letivo_deve_pertencer_a_escola

  def turno_humanizado
    I18n.t("activerecord.attributes.turma.turnos.#{turno}")
  end

  def nome_completo
    "#{nome} - #{escola.nome} (#{serie}º #{turno.humanize})"
  end

  def bimestres_disponiveis
    num_max = ano_letivo&.numero_bimestre || 4
    (1..num_max).to_a
  end

  def usa_nota?
    avaliacao_nota?
  end

  def usa_conceito?
    avaliacao_conceito?
  end

  private

  def ano_letivo_deve_pertencer_a_escola
    return unless ano_letivo.present? && escola.present?

    if ano_letivo.escola_id != escola.id
      errors.add(:base, "O Ano Letivo selecionado não pertence a esta Escola.")
    end
  end

  def verificar_alunos_vinculados
    if alunos.exists?
      errors.add(:base, "Não é possível excluir a turma pois existem #{alunos.count} aluno(s) vinculado(s).")
      throw :abort
    end
  end
end