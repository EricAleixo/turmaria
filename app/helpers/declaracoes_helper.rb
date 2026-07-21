module DeclaracoesHelper
  def declaracoes_section_path?
    controller_name == "declaracoes"
  end

  def interpolar_declaracao_corpo(texto, aluno, turma, ano_letivo, escola)
    cpf_texto   = aluno.respond_to?(:cpf) && aluno.cpf.present? ? ", inscrito(a) no CPF nº #{aluno.cpf}," : ","
    serie_texto = turma.respond_to?(:serie) && turma.serie.present? ? "no #{turma.serie} " : ""
    turno_texto = turma.respond_to?(:turno) && turma.turno.present? ? ", turno #{turma.turno}" : ""

    valores = {
      aluno_nome: aluno.nome,
      aluno_cpf: aluno.respond_to?(:cpf) ? aluno.cpf : "",
      cpf_texto: cpf_texto,
      serie_texto: serie_texto,
      turma_nome: turma.nome,
      turno_texto: turno_texto,
      ano_letivo_ano: ano_letivo.ano,
      aluno_matricula: aluno.matricula,
      escola_nome: escola.nome
    }

    valores.reduce(texto) do |txt, (chave, valor)|
      txt.gsub("%{#{chave}}", valor.to_s)
    end
  end
end