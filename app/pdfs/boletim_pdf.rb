# app/pdfs/boletim_pdf.rb
require 'prawn/table'

class BoletimPdf < Prawn::Document
  def initialize(aluno, turma, ano_letivo, boletim_disciplinas, frequencia_por_disciplina, view)
    super(page_size: 'A4', page_layout: :portrait)

    @aluno  = aluno
    @turma = turma
    @ano_letivo = ano_letivo
    @boletim_disciplinas = boletim_disciplinas
    @frequencia_por_disciplina = frequencia_por_disciplina
    @view = view
    @usa_conceito = turma.usa_conceito?

    font_size 10

    header
    student_data
    notes_table
    final_result
    assinatura
  end

  def header
    text "BOLETIM ESCOLAR", size: 18, style: :bold, align: :center
    stroke_horizontal_rule
    move_down 5
    text "Emitido em #{Time.zone.now.strftime('%d/%m/%Y')}", size: 8, align: :right
    move_down 10
  end

  def student_data
    tipo_avaliacao_label = @usa_conceito ? "Conceito" : "Nota"

    data = [
      ["ESCOLA:",      @aluno.escola.nome.upcase,    "MATRÍCULA:",    @aluno.matricula],
      ["ALUNO:",       @aluno.nome.upcase,            "IDADE:",        "#{@aluno.idade || 'N/A'} anos"],
      ["SÉRIE/ANO:",   "#{@turma.serie}º Ano",        "TURMA:",        @turma.nome],
      ["TURNO:",       @turma.turno.capitalize,       "ANO LETIVO:",   @ano_letivo.ano],
      ["AVALIAÇÃO:",   tipo_avaliacao_label,          "",              ""]
    ]

    table(data, column_widths: [80, 200, 80, 150]) do
      cells.padding      = 5
      cells.borders      = [:top, :bottom, :left, :right]
      cells.border_width = 0.5
      column(0).font_style = :bold
      column(2).font_style = :bold
      cells.background_color = 'F2F2F2'
    end
    move_down 15
  end

  def notes_table
    @usa_conceito ? notes_table_conceito : notes_table_nota
  end

  def final_result
    @usa_conceito ? final_result_conceito : final_result_nota
  end

  # -------------------------------------------------------
  # TABELA — TURMA DE NOTA
  # -------------------------------------------------------
  def notes_table_nota
    data    = []
    num_bim = @ano_letivo.numero_bimestre || 4

    headers = ["DISCIPLINA"]
    num_bim.times { |i| headers << "Média #{i + 1}º Bim" }
    headers += ["Faltas", "Recup", "Média Final", "Situação"]
    data << headers

    @boletim_disciplinas.each do |disciplina, avaliacoes|
      row              = [disciplina.nome.upcase]
      notas_bimestrais = {}
      avaliacoes.each { |av| notas_bimestrais[av.bimestre] = av.nota_bimestre_final }

      notas_validas    = notas_bimestrais.values.compact
      media_simples    = notas_validas.any? ? (notas_validas.sum.to_f / notas_validas.size).round(2) : nil
      nota_recuperacao = nil
      media_final_ano  = media_simples&.round(1)

      if nota_recuperacao.present? && media_final_ano.present?
        media_final_ano = [media_final_ano, nota_recuperacao].max.round(1)
      end

      freq_data             = @frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }
      total_faltas          = freq_data[:total_faltas]
      frequencia_percentual = freq_data[:total_aulas] > 0 ?
                              ((freq_data[:total_aulas] - total_faltas).to_f / freq_data[:total_aulas]) * 100 : nil

      situacao_final = @view.determinar_situacao_final(media_final_ano, frequencia_percentual)

      num_bim.times do |i|
        nota = notas_bimestrais[i + 1]
        row << (nota.present? ? ('%.1f' % nota) : '0.0')
      end

      row << total_faltas.to_s
      row << (nota_recuperacao.present? ? ('%.1f' % nota_recuperacao) : '0')
      row << (media_final_ano.present? ? ('%.1f' % media_final_ano) : '0.0')
      row << situacao_final[:texto].upcase

      data << row
    end

    table(data, header: true) do
      row(0).background_color = '404040'
      row(0).text_color       = 'FFFFFF'
      row(0).font_style       = :bold
      cells.borders           = [:top, :bottom, :left, :right]
      cells.border_width      = 0.5
      cells.padding           = 4
      columns(1..-1).align    = :center
    end
    move_down 15
  end

  # -------------------------------------------------------
  # TABELA — TURMA DE CONCEITO
  # -------------------------------------------------------
  def notes_table_conceito
    data    = []
    num_bim = @ano_letivo.numero_bimestre || 4

    headers = ["DISCIPLINA"]
    num_bim.times { |i| headers << "Conceito #{i + 1}º Bim" }
    headers += ["Faltas", "Situação"]
    data << headers

    # Para conceito buscamos direto de RegistroDeNota
    config_ids_por_disciplina = AvaliacaoConfiguracao
      .where(turma: @turma)
      .group_by(&:disciplina_id)

    disciplinas = config_ids_por_disciplina.keys.map { |id| Disciplina.find(id) }.sort_by(&:nome)

    disciplinas.each do |disciplina|
      row     = [disciplina.nome.upcase]
      configs = config_ids_por_disciplina[disciplina.id] || []

      conceitos_por_bimestre = {}
      configs.each do |config|
        registro = RegistroDeNota.find_by(
          aluno_id: @aluno.id,
          avaliacao_configuracao_id: config.id
        )
        next unless registro&.conceito.present?
        conceitos_por_bimestre[config.bimestre] ||= registro.conceito
      end

      num_bim.times do |i|
        conceito = conceitos_por_bimestre[i + 1]
        row << (conceito.present? ? conceito.upcase : '—')
      end

      freq_data    = @frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }
      total_faltas = freq_data[:total_faltas]

      # Situação por frequência
      frequencia_percentual = freq_data[:total_aulas] > 0 ?
                              ((freq_data[:total_aulas] - total_faltas).to_f / freq_data[:total_aulas]) * 100 : nil

      situacao = if frequencia_percentual && frequencia_percentual < 75
                   "REPROVADO POR FALTA"
                 elsif conceitos_por_bimestre.values.any?
                   melhor = conceitos_por_bimestre.values.max_by { |c| { "d" => 0, "c" => 1, "b" => 2, "a" => 3 }[c] || 0 }
                   melhor == "d" ? "INSUFICIENTE" : "APROVADO"
                 else
                   "AGUARDANDO"
                 end

      row << total_faltas.to_s
      row << situacao

      data << row
    end

    table(data, header: true) do
      row(0).background_color = '404040'
      row(0).text_color       = 'FFFFFF'
      row(0).font_style       = :bold
      cells.borders           = [:top, :bottom, :left, :right]
      cells.border_width      = 0.5
      cells.padding           = 4
      columns(1..-1).align    = :center
    end
    move_down 15
  end

  # -------------------------------------------------------
  # RESULTADO FINAL — TURMA DE NOTA
  # -------------------------------------------------------
  def final_result_nota
    reprovado_em_alguma = @boletim_disciplinas.keys.any? do |disciplina|
      notas_validas = @boletim_disciplinas[disciplina].map(&:nota_bimestre_final).compact
      media_simples = notas_validas.any? ? (notas_validas.sum.to_f / notas_validas.size).round(2) : nil

      freq_data             = @frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }
      total_faltas          = freq_data[:total_faltas]
      frequencia_percentual = freq_data[:total_aulas] > 0 ?
                              ((freq_data[:total_aulas] - total_faltas).to_f / freq_data[:total_aulas]) * 100 : nil

      situacao = @view.determinar_situacao_final(media_simples, frequencia_percentual)
      situacao[:texto] == 'Reprovado' || situacao[:texto] == 'Reprovado por Falta'
    end

    resultado_texto = reprovado_em_alguma ? "REPROVADO" : "APROVADO"
    cor_texto       = reprovado_em_alguma ? "FF0000"    : "008000"

    text "<b>RESULTADO FINAL: </b> <color rgb='#{cor_texto}'><b>#{resultado_texto}</b></color>",
         inline_format: true, size: 12, style: :bold

    move_down 5
    stroke_horizontal_rule
    move_down 20
  end

  # -------------------------------------------------------
  # RESULTADO FINAL — TURMA DE CONCEITO
  # -------------------------------------------------------
  def final_result_conceito
    config_ids = AvaliacaoConfiguracao.where(turma: @turma).pluck(:id)

    registros = RegistroDeNota
      .where(aluno_id: @aluno.id, avaliacao_configuracao_id: config_ids)
      .where.not(conceito: nil)

    conceitos = registros.map(&:conceito)
    ordem     = { "d" => 0, "c" => 1, "b" => 2, "a" => 3 }

    reprovado_por_conceito = conceitos.any? { |c| c == "d" }

    reprovado_por_falta = @frequencia_por_disciplina.values.any? do |freq|
      freq[:total_aulas] > 0 &&
        ((freq[:total_aulas] - freq[:total_faltas]).to_f / freq[:total_aulas]) * 100 < 75
    end

    resultado_texto = if reprovado_por_falta
                        "REPROVADO POR FALTA"
                      elsif conceitos.empty?
                        "AGUARDANDO"
                      elsif reprovado_por_conceito
                        "INSUFICIENTE"
                      else
                        "APROVADO"
                      end

    cor_texto = %w[REPROVADO POR FALTA INSUFICIENTE].any? { |t| resultado_texto.include?(t) } ? "FF0000" : "008000"
    cor_texto = "888888" if resultado_texto == "AGUARDANDO"

    text "<b>RESULTADO FINAL: </b> <color rgb='#{cor_texto}'><b>#{resultado_texto}</b></color>",
         inline_format: true, size: 12, style: :bold

    move_down 5
    stroke_horizontal_rule
    move_down 20
  end

  def assinatura
    text "___________________________________", align: :center
    text "Secretaria Escolar", align: :center, size: 9
  end
end