# app/pdfs/boletim_pdf.rb
require 'prawn/table'

class BoletimPdf < Prawn::Document
  def initialize(aluno, turma, ano_letivo, boletim_disciplinas, frequencia_por_disciplina, view)
    # Define o tamanho da página (A4)
    super(page_size: 'A4', page_layout: :portrait) 
    
    @aluno = aluno
    @turma = turma
    @ano_letivo = ano_letivo
    @boletim_disciplinas = boletim_disciplinas
    @frequencia_por_disciplina = frequencia_por_disciplina
    @view = view # Para acessar helpers como determinar_situacao_final
    
    font_size 10
    
    header
    student_data
    notes_table
    final_result
    
    # Adiciona a linha final para o campo de assinatura
    assinatura
  end
  
  # --- Cabeçalho ---
  def header
    text "BOLETIM ESCOLAR", size: 18, style: :bold, align: :center
    stroke_horizontal_rule
    move_down 5
    text "Emitido em #{Time.zone.now.strftime('%d/%m/%Y')}", size: 8, align: :right
    move_down 10
  end

  # --- Dados do Aluno ---
  def student_data
    data = [
      ["ESCOLA:", @aluno.escola.nome.upcase, "MATRÍCULA:", @aluno.matricula],
      ["ALUNO:", @aluno.nome.upcase, "IDADE:", "#{@aluno.idade || 'N/A'} anos"],
      ["SÉRIE/ANO:", "#{@turma.serie}º Ano", "TURMA:", @turma.nome],
      ["TURNO:", @turma.turno.capitalize, "ANO LETIVO:", @ano_letivo.ano]
    ]

    table(data, column_widths: [80, 200, 80, 150]) do
      cells.padding = 5
      cells.borders = [:top, :bottom, :left, :right]
      cells.border_width = 0.5
      
      column(0).font_style = :bold
      column(2).font_style = :bold
      cells.background_color = 'F2F2F2'
    end
    move_down 15
  end

  # --- Tabela de Notas e Frequência ---
  def notes_table
    data = []
    
    # Cabeçalho da Tabela
    headers = ["DISCIPLINA"]
    (@ano_letivo.numero_bimestre || 4).times { |i| headers << "Média #{i + 1}º Bim" }
    headers += ["Faltas", "Recup", "Média Final", "Situação Final"]
    data << headers

    # Preenchimento da Tabela (Corpo)
    @boletim_disciplinas.each do |disciplina, avaliacoes|
      row = [disciplina.nome.upcase]
      notas_bimestrais = {}
      avaliacoes.each { |av| notas_bimestrais[av.bimestre] = av.nota_bimestre_final }
      
      # Lógica de Cálculo (Migrada da sua view HTML)
      notas_validas = notas_bimestrais.values.compact
      media_simples = notas_validas.any? ? (notas_validas.sum.to_f / notas_validas.size).round(2) : nil
      nota_recuperacao = nil 

      media_final_ano = media_simples.present? ? media_simples.round(1) : nil
      if nota_recuperacao.present? && media_final_ano.present?
        media_final_ano = [media_final_ano, nota_recuperacao].max.round(1)
      end

      freq_data = @frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }
      total_faltas = freq_data[:total_faltas]
      frequencia_percentual = freq_data[:total_aulas] > 0 ? ((freq_data[:total_aulas] - total_faltas).to_f / freq_data[:total_aulas]) * 100 : nil
      
      situacao_final = @view.determinar_situacao_final(media_final_ano, frequencia_percentual) 

      # Adiciona as notas bimestrais
      (@ano_letivo.numero_bimestre || 4).times do |i|
        nota = notas_bimestrais[i + 1]
        row << (nota.present? ? '%.1f' % nota : '0.0')
      end

      # Adiciona Faltas, Recup, Média Final e Situação Final
      row << total_faltas.to_s
      row << (nota_recuperacao.present? ? ('%.1f' % nota_recuperacao) : '0')
      row << (media_final_ano.present? ? ('%.1f' % media_final_ano) : '0.0')
      row << situacao_final[:texto].upcase

      data << row
    end
    
    # Desenha a tabela completa
    table(data, header: true) do
      row(0).background_color = '404040'
      row(0).text_color = 'FFFFFF'
      row(0).font_style = :bold
      
      cells.borders = [:top, :bottom, :left, :right]
      cells.border_width = 0.5
      cells.padding = 4
      
      columns(1..-1).align = :center 
    end
    move_down 15
  end
  
  # --- Resultado Final Global ---
  def final_result
    # Lógica de Reprovação Global (Migrada da sua view HTML)
    reprovado_em_alguma = @boletim_disciplinas.keys.any? do |disciplina|
      notas_validas_d = @boletim_disciplinas[disciplina].map(&:nota_bimestre_final).compact
      media_simples_d = notas_validas_d.any? ? (notas_validas_d.sum.to_f / notas_validas_d.size).round(2) : nil
      media_final_global = media_simples_d
      
      freq_data_d = @frequencia_por_disciplina[disciplina.id] || { total_aulas: 0, total_faltas: 0 }
      total_faltas_d = freq_data_d[:total_faltas]
      frequencia_percentual_d = freq_data_d[:total_aulas] > 0 ? ((freq_data_d[:total_aulas] - total_faltas_d).to_f / freq_data_d[:total_aulas]) * 100 : nil
      
      final_situacao = @view.determinar_situacao_final(media_final_global, frequencia_percentual_d)
      
      final_situacao[:texto] == 'Reprovado' || final_situacao[:texto] == 'Reprovado por Falta'
    end

    resultado_texto = reprovado_em_alguma ? "REPROVADO" : "APROVADO"
    cor_texto = reprovado_em_alguma ? "FF0000" : "008000" # Vermelho ou Verde (Hexadecimal)

    # Imprime o resultado final
    text "<b>RESULTADO FINAL: </b> <color rgb='#{cor_texto}'><b>#{resultado_texto}</b></color>", 
         inline_format: true, size: 12, style: :bold
    
    move_down 5
    stroke_horizontal_rule
    move_down 20
  end
  
  # --- Assinatura ---
  def assinatura
      # Cria um espaço para a assinatura centralizado
      text "___________________________________", align: :center
      text "Secretaria Escolar", align: :center, size: 9
  end
end