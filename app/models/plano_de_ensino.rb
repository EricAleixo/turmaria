class PlanoDeEnsino < ApplicationRecord
  enum status: { rascunho: 0, em_elaboracao: 1, publicado: 2 }

  belongs_to :professor
  belongs_to :turma
  belongs_to :disciplina

  validates :bimestre, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :status, presence: true

  validate :turma_pertence_ao_professor
  validate :disciplina_pertence_ao_professor
  validate :disciplina_lecionada_na_turma
  validate :bimestre_valido_para_a_turma

  # Atalhos: essas infos já existem em Turma, não precisam de coluna própria aqui
  delegate :serie, :turno, :nome, to: :turma, prefix: :turma
  delegate :ano_letivo, to: :turma
  delegate :nome, to: :disciplina, prefix: :disciplina

  def status_humanizado
    I18n.t("activerecord.attributes.plano_de_ensino.status.#{status}", default: status.humanize)
  end

  STATUS_CORES = {
    "rascunho" => "gray",
    "em_elaboracao" => "blue",
    "publicado" => "green"
  }.freeze

  def status_cor
    STATUS_CORES.fetch(status, "gray")
  end

  # Não existe campo de título — cai pra um resumo da ementa,
  # e por último pra "Disciplina - Nº Bimestre" se nem ementa tiver.
  def titulo
    return ementa.truncate(60) if ementa.present?

    "#{disciplina_nome} · #{bimestre}º Bimestre"
  end

  private

  def turma_pertence_ao_professor
    return if professor.blank? || turma.blank?

    unless professor.turmas.exists?(id: turma_id)
      errors.add(:turma_id, "não pertence a este professor")
    end
  end

  def disciplina_pertence_ao_professor
    return if professor.blank? || disciplina.blank?

    unless professor.disciplinas.exists?(id: disciplina_id)
      errors.add(:disciplina_id, "não é lecionada por este professor")
    end
  end

  def disciplina_lecionada_na_turma
    return if turma.blank? || disciplina.blank?

    unless turma.disciplinas.exists?(id: disciplina_id)
      errors.add(:disciplina_id, "não está vinculada a esta turma")
    end
  end

  def bimestre_valido_para_a_turma
    return if turma.blank? || bimestre.blank?

    disponiveis = turma.bimestres_disponiveis
    unless disponiveis.include?(bimestre)
      errors.add(:bimestre, "deve estar entre #{disponiveis.first} e #{disponiveis.last} para esta turma")
    end
  end
end