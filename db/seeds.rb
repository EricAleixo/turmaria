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
  email: "superadmin@teste.com",
  password: "123456",
  confirmed_at: Time.current
)
puts super_admin.persisted? ? "SuperAdmin criado!" : "Erro: #{super_admin.errors.full_messages.join(", ")}"

puts "Criando Admin..."
admin = Admin.create(
  email: "admin@teste.com",
  password: "123456",
  confirmed_at: Time.current
)
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

puts "Criando Aluno de Teste e Registro de Login..."
aluno_email = "luan@teste.com" # ALTERADO para ser consistente com o nome
aluno_password = "123456"

# 1. Criação/Atualização do Objeto Aluno (com Devise)
aluno = Aluno.find_or_initialize_by(email: aluno_email)

if aluno.new_record? || aluno.password_digest.blank? || aluno.confirmed_at.nil?
  # Adicionando a atribuição do NOME aqui:
  aluno.nome = "Luan" 
  
  aluno.password = aluno_password
  aluno.password_confirmation = aluno_password
  aluno.confirmed_at = Time.current # Necessário para o Devise :confirmable
  aluno.escola = escola # Associa a escola criada

  if aluno.save
    puts "Aluno de Teste 'Luan' criado/atualizado!"
  else
    puts "❌ ERRO ao salvar Aluno: #{aluno.errors.full_messages.to_sentence}"
  end
end


# 2. Criação/Atualização do EmailCadastro (Registro Polimórfico)
if aluno.persisted?
  email_cadastro = EmailCadastro.find_or_initialize_by(email: aluno.email)

  # AQUI está a atribuição polimórfica que resolve todos os erros de validação:
  email_cadastro.user = aluno

  if email_cadastro.save
    puts "Registro EmailCadastro criado/atualizado para Aluno."
  else
    puts "❌ ERRO ao salvar EmailCadastro: #{email_cadastro.errors.full_messages.to_sentence}"
  end
end

puts "🌱 Seeds finalizados com sucesso!"
