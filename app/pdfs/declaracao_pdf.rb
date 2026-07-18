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
    text "Estado da Paraíba", align: :center, size: 11, style: :bold
    text "Secretaria de Estado da Educação", align: :center, size: 11, style: :bold
    text @escola&.nome.to_s.upcase, align: :center, size: 11, style: :bold
    move_down 20
  end

  def gerar_titulo
    text "DECLARAÇÃO", align: :center, size: 14, style: :bold
    move_down 20
  end

  def gerar_corpo
    cpf_texto   = @aluno.respond_to?(:cpf) && @aluno.cpf.present? ? ", inscrito(a) no CPF nº #{@aluno.cpf}," : ","
    serie_texto = @turma.respond_to?(:serie) && @turma.serie.present? ? "no #{@turma.serie} " : ""
    turno_texto = @turma.respond_to?(:turno) && @turma.turno.present? ? ", turno #{@turma.turno}" : ""

    text "Declaramos, para os devidos fins, que o(a) aluno(a) #{@aluno.nome}#{cpf_texto} " \
         "encontra-se regularmente matriculado(a) nesta instituição de ensino #{serie_texto}" \
         "na turma #{@turma.nome}#{turno_texto}, referente ao ano letivo de #{@ano_letivo.ano}, " \
         "sob a matrícula nº #{@aluno.matricula}.",
         align: :justify, size: 11, leading: 4

    move_down 15

    text "Informamos ainda que o(a) referido(a) estudante possui vínculo ativo com esta unidade " \
         "escolar e frequenta regularmente as atividades acadêmicas.",
         align: :justify, size: 11, leading: 4

    move_down 15

    text "A presente declaração é emitida a pedido do(a) interessado(a), para os fins que se " \
         "fizerem necessários.",
         align: :justify, size: 11, leading: 4

    move_down 40

    cidade = @escola.respond_to?(:cidade) && @escola.cidade.present? ? @escola.cidade : "Guarabira"
    estado = @escola.respond_to?(:estado) && @escola.estado.present? ? @escola.estado : "PB"

    text "#{cidade} – #{estado}, #{I18n.l(Date.current, format: :long)}.", size: 11
  end

  def gerar_assinatura
    move_down 60
    diretor = @escola.respond_to?(:diretor_nome) && @escola.diretor_nome.present? ? @escola.diretor_nome : nil

    text_box "_" * 40, at: [bounds.width / 2 - 100, cursor], width: 200, align: :center
    move_down 15
    text diretor || "Diretor(a) Escolar", align: :center, size: 10
    text "Diretor(a) Escolar", align: :center, size: 9, color: "666666" if diretor
  end

  def gerar_rodape
    move_down 30
    url_verificacao = @view_context.validar_declaracao_curta_url(codigo: @declaracao.codigo_curto)

    text "Código de Autenticidade: #{@declaracao.codigo_autenticidade}", align: :center, size: 8, color: "666666"
    text "Verifique em: #{url_verificacao}", align: :center, size: 8, color: "666666"

    move_down 10
    qr_png = RQRCode::QRCode.new(url_verificacao).as_png(size: 120)
    image StringIO.new(qr_png.to_s), width: 60, height: 60, position: :center
  end
end 