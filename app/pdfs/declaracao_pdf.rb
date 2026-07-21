require "cgi"

class DeclaracaoPdf < Prawn::Document
  def initialize(aluno, turma, ano_letivo, declaracao, view_context)
    super(page_size: 'A4', margin: [60, 60, 60, 60])
    @aluno = aluno
    @turma = turma
    @escola = aluno.escola
    @ano_letivo = ano_letivo
    @declaracao = declaracao
    @view_context = view_context

    gerar_cabecalho
    gerar_titulo
    gerar_corpo
    gerar_assinatura
    gerar_rodape
  end

  private

  def gerar_cabecalho
    if @escola.respond_to?(:declaracao_cabecalho) && @escola.declaracao_cabecalho.present?
      @escola.declaracao_cabecalho.each_line do |line|
        text line.strip, align: :center, size: 11, style: :bold
      end
    else
      text "Estado da Paraíba", align: :center, size: 11, style: :bold
      text "Secretaria de Estado da Educação", align: :center, size: 11, style: :bold
      text @escola&.nome.to_s.upcase, align: :center, size: 11, style: :bold
    end
    move_down 20
  end

  def gerar_titulo
    text "DECLARAÇÃO", align: :center, size: 14, style: :bold
    move_down 20
  end

  def gerar_corpo
    if @escola.respond_to?(:declaracao_corpo) && @escola.declaracao_corpo.present?
      corpo_interpolado = interpolar_corpo(@escola.declaracao_corpo)
      
      corpo_interpolado.split("\n\n").each do |paragrafo|
        next if paragrafo.blank?
        text paragrafo.strip, align: :justify, size: 11, leading: 4, inline_format: true
        move_down 15
      end
    else
      cpf_texto   = @aluno.respond_to?(:cpf) && @aluno.cpf.present? ? ", inscrito(a) no CPF nº #{@aluno.cpf}," : ","
      serie_texto = @turma.respond_to?(:serie) && @turma.serie.present? ? "no #{@turma.serie} " : ""
      turno_texto = @turma.respond_to?(:turno) && @turma.turno.present? ? ", turno #{@turma.turno}" : ""

      text "Declaramos, para os devidos fins, que o(a) aluno(a) <b>#{CGI.escapeHTML(@aluno.nome.to_s)}</b>#{cpf_texto} " \
           "encontra-se regularmente matriculado(a) nesta instituição de ensino #{serie_texto}" \
           "na turma <b>#{CGI.escapeHTML(@turma.nome.to_s)}</b>#{turno_texto}, referente ao ano letivo de #{@ano_letivo.ano}, " \
           "sob a matrícula nº #{@aluno.matricula}.",
           align: :justify, size: 11, leading: 4, inline_format: true

      move_down 15

      text "Informamos ainda que o(a) referido(a) estudante possui vínculo ativo com esta unidade " \
           "escolar e frequenta regularmente as atividades acadêmicas.",
           align: :justify, size: 11, leading: 4

      move_down 15

      text "A presente declaração é emitida a pedido do(a) interessado(a), para os fins que se " \
           "fizerem necessários.",
           align: :justify, size: 11, leading: 4
    end

    move_down 40

    cidade = @escola.respond_to?(:cidade) && @escola.cidade.present? ? @escola.cidade : "Guarabira"
    estado = @escola.respond_to?(:estado) && @escola.estado.present? ? @escola.estado : "PB"

    text "#{cidade} – #{estado}, #{I18n.l(Date.current, format: :long)}.", size: 11
  end

  def interpolar_corpo(texto)
    # Escapa o texto digitado pela escola primeiro (para não quebrar o parser
    # de negrito caso alguém digite "<" ou "&" por acaso), e só depois insere
    # as tags de negrito nas variáveis — assim elas continuam funcionando.
    texto_escapado = CGI.escapeHTML(texto)

    cpf_texto   = @aluno.respond_to?(:cpf) && @aluno.cpf.present? ? ", inscrito(a) no CPF nº #{@aluno.cpf}," : ","
    serie_texto = @turma.respond_to?(:serie) && @turma.serie.present? ? "no #{@turma.serie} " : ""
    turno_texto = @turma.respond_to?(:turno) && @turma.turno.present? ? ", turno #{@turma.turno}" : ""

    valores = {
      aluno_nome: "<b>#{CGI.escapeHTML(@aluno.nome.to_s)}</b>",
      aluno_cpf: @aluno.respond_to?(:cpf) ? @aluno.cpf : "",
      cpf_texto: cpf_texto,
      serie_texto: serie_texto,
      turma_nome: "<b>#{CGI.escapeHTML(@turma.nome.to_s)}</b>",
      turno_texto: turno_texto,
      ano_letivo_ano: @ano_letivo.ano,
      aluno_matricula: @aluno.matricula,
      escola_nome: @escola.nome
    }

    valores.reduce(texto_escapado) do |txt, (chave, valor)|
      txt.gsub("%{#{chave}}", valor.to_s)
    end
  end

  def gerar_assinatura
    move_down 60

    cargo = if @escola.respond_to?(:declaracao_assinatura_cargo) && @escola.declaracao_assinatura_cargo.present?
              @escola.declaracao_assinatura_cargo
            else
              "Diretor(a) Escolar"
            end

    # Se a escola tiver uma assinatura desenhada (imagem base64), desenha ela
    # logo acima do traço, no lugar de deixar o espaço em branco.
    desenhar_assinatura_imagem

    text_box "_" * 28, at: [bounds.width / 2 - 100, cursor], width: 200, align: :center
    move_down 15
    text cargo, align: :center, size: 10
  end

  def desenhar_assinatura_imagem
    return unless @escola.respond_to?(:declaracao_assinatura_imagem)

    base64_data = @escola.declaracao_assinatura_imagem
    return if base64_data.blank?

    # Remove o prefixo "data:image/png;base64," caso venha junto (é o formato
    # que o canvas.toDataURL() do navegador gera).
    base64_puro = base64_data.to_s.sub(/\Adata:image\/\w+;base64,/, "")
    binario = Base64.decode64(base64_puro)

    largura_assinatura = 160
    altura_assinatura = 65

    # Deslocamento ajustado manualmente na tela "Posicionar Assinatura"
    # (arrastar). x positivo desloca para a direita, y positivo desloca
    # para cima — mesma convenção usada no JS daquela tela.
    offset_x = escola_atributo_numerico(:declaracao_assinatura_pos_x)
    offset_y = escola_atributo_numerico(:declaracao_assinatura_pos_y)

    pos_x = (bounds.width - largura_assinatura) / 2.0 + offset_x
    pos_y = cursor + offset_y

    image StringIO.new(binario),
          at: [pos_x, pos_y],
          width: largura_assinatura,
          height: altura_assinatura

    move_down(altura_assinatura + 2)
  rescue StandardError => e
    # Se a imagem estiver corrompida ou não for um base64 válido, apenas
    # ignora e segue com o traço de assinatura em branco, sem quebrar o PDF.
    Rails.logger.warn("[DeclaracaoPdf] Falha ao desenhar assinatura da escola #{@escola&.id}: #{e.message}")
  end

  def escola_atributo_numerico(nome_atributo)
    return 0.0 unless @escola.respond_to?(nome_atributo)

    valor = @escola.public_send(nome_atributo)
    valor.present? ? valor.to_f : 0.0
  end

  def gerar_rodape
    url_verificacao = @view_context.validar_declaracao_curta_url(codigo: @declaracao.codigo_curto)

    qr_tamanho = 100 # pt — aumentado (antes era 60pt)
    espaco_reservado_qr = qr_tamanho + 15

    # Posições absolutas em relação ao rodapé da página (não dependem mais de
    # onde o cursor parou depois do corpo do texto/assinatura) — assim o
    # rodapé sempre fica fixo na mesma altura, colado na base da página.
    text_box "Código de Autenticidade: #{@declaracao.codigo_autenticidade}",
             at: [0, 42], width: bounds.width - espaco_reservado_qr, size: 8, color: "666666"

    text_box "Verifique em: #{url_verificacao}",
             at: [0, 28], width: bounds.width - espaco_reservado_qr, size: 8, color: "666666"

    # Resolução do PNG maior que o tamanho impresso, para não ficar
    # pixelizado agora que o QR Code está maior no PDF.
    qr_png = RQRCode::QRCode.new(url_verificacao).as_png(size: 300)

    image StringIO.new(qr_png.to_s),
          at: [bounds.width - qr_tamanho, qr_tamanho],
          width: qr_tamanho,
          height: qr_tamanho
  end
end