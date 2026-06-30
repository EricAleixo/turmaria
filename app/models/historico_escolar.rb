class HistoricoEscolar < ApplicationRecord
  belongs_to :aluno
  belongs_to :escola
  belongs_to :ano_letivo
  has_many :historico_disciplinas, dependent: :destroy

  validates :serie_turma,   presence: true
  validates :situacao_final, presence: true,
            inclusion: { in: %w[aprovado reprovado reprovado_falta recuperacao aguardando] }
  validates :aluno_id, uniqueness: {
    scope: [:escola_id, :ano_letivo_id],
    message: "já tem histórico nesta escola/ano"
  }

  def self.gerar!(aluno:, turma:, ano_letivo:, boletim_disciplinas:, frequencia_por_disciplina:)
    escola = turma.escola

    historico = find_or_initialize_by(
      aluno_id:      aluno.id,
      escola_id:     escola.id,
      ano_letivo_id: ano_letivo.id
    )

    pcts = frequencia_por_disciplina.values.map do |f|
      next nil if f[:total_aulas].to_i.zero?
      ((f[:total_aulas] - f[:total_faltas]).to_f / f[:total_aulas] * 100).round(2)
    end.compact
    freq_geral = pcts.any? ? (pcts.sum / pcts.size).round(2) : nil

    todas_notas = boletim_disciplinas.values.flat_map { |avs| avs.map(&:nota_bimestre_final).compact }
    media_geral = todas_notas.any? ? (todas_notas.sum / todas_notas.size).round(2) : nil

    historico.assign_attributes(
      serie_turma:          "#{turma.serie}º #{turma.nome}",
      turno:                turma.turno,
      situacao_final:       calcular_situacao(media_geral, freq_geral),
      frequencia_geral_pct: freq_geral,
      gerado_em:            Time.current
    )
    historico.save!

    boletim_disciplinas.each do |disciplina, avaliacoes|
      freq = frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }

      hd = historico.historico_disciplinas
                    .find_or_initialize_by(disciplina_nome: disciplina.nome)

      avaliacoes.each do |av|
        if turma.usa_nota?
          hd.assign_attributes("nota_b#{av.bimestre}" => av.nota_bimestre_final)
        else
          hd.assign_attributes("conceito_b#{av.bimestre}" => av.conceito)
        end
      end

      if turma.usa_nota?
        notas = (1..4).map { |b| hd.send("nota_b#{b}") }.compact
        hd.media_final = notas.any? ? (notas.sum / notas.size).round(2) : nil
      else
        hd.conceito_final = avaliacoes.last&.conceito
      end

      hd.aulas_dadas  = freq[:total_aulas].to_i
      hd.total_faltas = freq[:total_faltas].to_i
      hd.save!
    end

    historico
  end

  def self.calcular_situacao(media, frequencia)
    media_minima      = 6.0
    frequencia_minima = 75.0

    return 'aguardando'      if media.nil? || frequencia.nil?
    return 'reprovado_falta' if frequencia < frequencia_minima
    return 'aprovado'        if media >= media_minima
    return 'recuperacao'     if media >= (media_minima - 1)
    'reprovado'
  end
end