json.extract! aluno, :id, :nome, :data_nascimento, :created_at, :updated_at
json.url aluno_url(aluno, format: :json)
