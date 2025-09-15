class AddMoreFieldsToAlunos < ActiveRecord::Migration[7.1]
  def change
    add_column :alunos, :cpf, :string
    add_column :alunos, :rg, :string
    add_column :alunos, :telefone, :string
    add_column :alunos, :email, :string
    add_column :alunos, :sexo, :string
    add_column :alunos, :cor, :string
    add_column :alunos, :tipo_sanguinio, :string
    add_column :alunos, :necessidades_especiais_tipo, :string
    add_column :alunos, :observacoes_pcd, :text
    add_column :alunos, :responsavel_1, :string
    add_column :alunos, :responsavel_2, :string
    add_column :alunos, :telefone_responsavel_1, :string
    add_column :alunos, :telefone_responsavel_2, :string
    add_column :alunos, :foto_url, :string
    add_column :alunos, :cpf_url, :string
    add_column :alunos, :comprovante_residencia_url, :string
    add_column :alunos, :historico_academico_url, :string
  end
end
