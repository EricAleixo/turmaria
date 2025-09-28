json.extract! aluno, :id, :nome, :data_nascimento, :created_at, :updated_at
json.url aluno_url(aluno, format: :json)

if aluno.turma.present?
  json.url escola_turma_aluno_url(aluno.escola, aluno.turma, aluno, format: :json)
else
  json.url escola_aluno_url(aluno.escola, aluno, format: :json)
end