puts "Limpando registros antigos..."
SuperAdmin.delete_all
Admin.delete_all
Professor.delete_all
Escola.delete_all
Cidade.delete_all
Estado.delete_all

puts "Criando Estado e Cidade..."
estado = Estado.create!(nome: "São Paulo")
cidade = Cidade.create!(nome: "Campinas", estado: estado)

puts "Criando Escola..."
escola = Escola.create!(
  nome: "Escola Municipal Exemplo",
  cnpj: "12.345.678/0001-98",
  telefone: "1234-5677",
  email: "contato@escolaexemplo.com",
  site: "www.escolaexemplo.com",
  tipo: "privada"
)

puts "Criando SuperAdmin..."
super_admin = SuperAdmin.create(
  email: "turmaria@gmail.com",
  password: "turmariaoficial8090",
  confirmed_at: Time.current
)
puts super_admin.persisted? ? "SuperAdmin criado!" : "Erro: #{super_admin.errors.full_messages.join(", ")}"

puts "Criando Admin..."

admin = Admin.create!(
  nome: "Administrador",
  email: "turmaria@gmail.com",
  password: "turmariaoficial8090",
  password_confirmation: "turmariaoficial8090",
  confirmed_at: Time.current
)

puts "✅ Administrador criado!"
puts admin.persisted? ? "Admin criado!" : "Erro: #{admin.errors.full_messages.join(", ")}"

puts "Criando Professores..."
10.times do |i|
  prof = Professor.create(
    email: "professor#{i+1}@teste.com",
    nome: "professor#{i+1}",
    cpf: rand(100_000_000..999_999_999).to_s, # gera 9 dígitos aleatórios
    password: "123456",
    confirmed_at: Time.current,
    escola: escola
  )

  if prof.persisted?
    puts "Professor #{i+1} criado!"
  else
    puts "Erro Professor #{i+1}: #{prof.errors.full_messages.join(", ")}"
  end
end


puts "Criando Alunos de Teste..."
Aluno.delete_all

10.times do |i|
  aluno = Aluno.find_or_initialize_by(email: "aluno#{i+1}@teste.com")
  aluno.nome = "Aluno #{i+1}"
  aluno.password = "12345678"
  aluno.password_confirmation = "12345678"
  aluno.confirmed_at = Time.current
  aluno.escola = Escola.find_by_cnpj("12.345.678/0001-98") # associa a escola criada

  if aluno.save
    puts "Aluno #{i+1} criado!"
    
    # Criação do registro polimórfico EmailCadastro
    email_cadastro = EmailCadastro.find_or_initialize_by(email: aluno.email)
    email_cadastro.user = aluno
    if email_cadastro.save
      puts "  → EmailCadastro criado para #{aluno.email}"
    else
      puts "  ❌ Erro EmailCadastro: #{email_cadastro.errors.full_messages.to_sentence}"
    end

  else
    puts "❌ Erro Aluno #{i+1}: #{aluno.errors.full_messages.join(", ")}"
  end
end


puts "🌱 Seeds finalizados com sucesso!"
