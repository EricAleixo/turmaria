module Aluno::TurmaLookup
  extend ActiveSupport::Concern

  private

  def buscar_turma_do_aluno_no_ano(aluno, ano_letivo)
    turma = Turma.joins(:avaliacoes_bimestrais)
                 .where(ano_letivo_id: ano_letivo.id,
                        avaliacoes_bimestrais: { aluno_id: aluno.id })
                 .first

    turma ||= Turma.joins(avaliacoes_configuracoes: :registros_de_notas)
                    .where(ano_letivo_id: ano_letivo.id,
                           registros_de_notas: { aluno_id: aluno.id })
                    .first

    turma ||= aluno.turma if aluno.turma&.ano_letivo_id == ano_letivo.id

    turma
  end
end