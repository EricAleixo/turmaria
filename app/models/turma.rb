class Turma < ApplicationRecord
  enum turno: {manha:0, tarde:1, noite:2, integral:3 }

  # --- Associações Principais ---
  belongs_to :ano_letivo
  belongs_to :escola, counter_cache: true
  has_many :alunos
  
  # --- Associações com Professores (Para Turmas) ---
  has_many :professor_turmas
  has_many :professores, through: :professor_turmas
  
  # --- ASSOCIAÇÃO ADICIONADA PARA DISCIPLINAS (Resolve o erro) ---
  has_many :turma_disciplinas
  has_many :disciplinas, through: :turma_disciplinas
  
  # --- Associações de Frequência e Notas ---
  has_many :frequencias, dependent: :destroy
  has_many :avaliacoes_configuracoes, class_name: 'AvaliacaoConfiguracao'
  has_many :avaliacoes_bimestrais

  # --- Validações ---
  validates :nome, presence: true
  validates :serie, presence: true
  validate :ano_letivo_deve_pertencer_a_escola

  def nome_completo
    "#{nome} - #{escola.nome} (#{serie}º #{turno.humanize})"
  end

  private

  def ano_letivo_deve_pertencer_a_escola
    return unless ano_letivo.present? && escola.present?

    if ano_letivo.escola_id != escola.id
      Rails.logger.error " ERRO! Tentativa de Turma (Escola #{escola.id}) usar Ano Letivo (Escola #{ano_letivo.escola_id})"

      errors.add(:base, "O Ano Letivo selecionado não pertence a esta Escola.")
    end
  end
end
