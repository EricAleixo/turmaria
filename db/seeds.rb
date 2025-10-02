puts "Criando estado e cidade..."
estado1 = Estado.create!(nome: "São Paulo 2")
cidade1 = Cidade.create!(nome: "Campinas 2", estado: estado1)

puts "Criando escola..."
escola1 = Escola.create!(
  nome: "Escola Municipal Exemplo 1",
  cnpj: "12.345.678/0001-98",
  telefone: "1234-5677",
  email: "contato@escolaexemplo1.com",
  site: "www.escolaexemplo1.com",
  tipo: "privada"
)

puts "Cidade e escola criadas com sucesso!"
