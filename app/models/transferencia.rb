# app/models/transferencia.rb
class Transferencia < ApplicationRecord
  belongs_to :aluno
  belongs_to :escola_origem,    class_name: 'Escola'
  belongs_to :escola_destino,   class_name: 'Escola'
  belongs_to :ano_letivo
  belongs_to :historico_escolar, optional: true

  validates :transferido_em, presence: true

  def self.executar!(aluno:, escola_destino:, ano_letivo:, turma:, boletim_disciplinas:, frequencia_por_disciplina:, motivo: nil)
    escola_origem = aluno.escola

    # Tudo dentro de uma transação — ou tudo funciona ou nada muda
    transaction do
      # 1. Gera o histórico da escola atual
      historico = HistoricoEscolar.gerar!(
        aluno:                     aluno,
        turma:                     turma,
        ano_letivo:                ano_letivo,
        boletim_disciplinas:       boletim_disciplinas,
        frequencia_por_disciplina: frequencia_por_disciplina
      )

      # 2. Registra a transferência
      transferencia = create!(
        aluno:             aluno,
        escola_origem:     escola_origem,
        escola_destino:    escola_destino,
        ano_letivo:        ano_letivo,
        historico_escolar: historico,
        motivo:            motivo,
        transferido_em:    Time.current
      )

      # 3. Desvincula da turma e muda de escola
      aluno.update!(
        turma:  nil,
        escola: escola_destino
      )

      transferencia
    end
  end
end