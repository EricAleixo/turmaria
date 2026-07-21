require "test_helper"

class DeclaracaoTest < ActiveSupport::TestCase
  test "interpolar_corpo interpolates variables correctly" do
    # We create database records to avoid validation failures
    escola = Escola.create!(nome: "Escola de Teste", tipo: "publica")
    turma = Turma.create!(nome: "3º Ano A", serie: "3º Ano", turno: "Manhã", escola: escola)
    aluno = Aluno.create!(
      nome: "João da Silva", 
      matricula: "1234567890", 
      escola: escola, 
      turma: turma,
      data_nascimento: Date.new(2010, 1, 1),
      sexo: "Masculino"
    )
    ano_letivo = AnoLetivo.create!(ano: 2026, data_inicio: Date.new(2026, 2, 1), data_fim: Date.new(2026, 12, 1), escola: escola)
    declaracao = Declaracao.create!(
      aluno: aluno, 
      turma: turma, 
      ano_letivo: ano_letivo, 
      escola: escola
    )

    pdf = DeclaracaoPdf.new(aluno, turma, ano_letivo, declaracao, nil)
    
    texto_corpo = "%{aluno_nome} matriculado no %{serie_texto}na turma %{turma_nome}%{turno_texto} no ano %{ano_letivo_ano} na escola %{escola_nome}."
    resultado = pdf.send(:interpolar_corpo, texto_corpo)
    
    assert_match "João da Silva", resultado
    assert_match "no 3º Ano", resultado
    assert_match "3º Ano A", resultado
    assert_match "Manhã", resultado
    assert_match "2026", resultado
    assert_match "Escola de Teste", resultado
  end
end
