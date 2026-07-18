# app/models/declaracao.rb
class Declaracao < ApplicationRecord
  belongs_to :aluno
  belongs_to :turma
  belongs_to :ano_letivo
  belongs_to :escola

  before_validation :gerar_codigo_autenticidade, on: :create
  before_validation :gerar_token, on: :create
  before_validation :gerar_codigo_curto, on: :create
  before_validation :definir_emitido_em, on: :create

  validates :codigo_autenticidade, presence: true, uniqueness: true
  validates :token, presence: true, uniqueness: true
  validates :codigo_curto, presence: true, uniqueness: true
  validates :emitido_em, presence: true

  scope :ativas, -> { where(ativa: true) }

  def self.emitir!(aluno:, turma:, ano_letivo:)
    ativas.find_by(aluno: aluno, ano_letivo: ano_letivo) ||
      create!(
        aluno: aluno,
        turma: turma,
        ano_letivo: ano_letivo,
        escola: aluno.escola,
        dados_snapshot: montar_snapshot(aluno, turma, ano_letivo)
      )
  end

  def self.montar_snapshot(aluno, turma, ano_letivo)
    {
      aluno_nome: aluno.nome,
      matricula: aluno.matricula,
      turma_nome: turma.nome,
      turma_serie: turma.respond_to?(:serie) ? turma.serie : nil,
      turma_turno: turma.respond_to?(:turno) ? turma.turno : nil,
      ano_letivo_ano: ano_letivo.ano,
      escola_nome: aluno.escola.nome
    }
  end

  def valida?
    ativa?
  end

  private

  def gerar_codigo_autenticidade
    self.codigo_autenticidade ||=
      "DEC-#{ano_letivo&.ano}-#{aluno&.matricula}-#{SecureRandom.hex(3).upcase}"
  end

  def gerar_token
    self.token ||= SecureRandom.uuid
  end

  # Código curto e legível pra caber num link e num QR code pequeno.
  # Evita caracteres ambíguos (0/O, 1/I/l) pra reduzir erro de digitação manual.
  def gerar_codigo_curto
    return if codigo_curto.present?

    alfabeto = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
    loop do
      candidato = 6.times.map { alfabeto[SecureRandom.random_number(alfabeto.length)] }.join
      if Declaracao.find_by(codigo_curto: candidato).nil?
        self.codigo_curto = candidato
        break
      end
    end
  end

  def definir_emitido_em
    self.emitido_em ||= Time.current
  end
end