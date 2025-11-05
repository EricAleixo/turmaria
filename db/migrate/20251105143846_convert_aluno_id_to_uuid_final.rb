class ConvertAlunoIdToUuidFinal < ActiveRecord::Migration[7.1]
  def change
    # 1. Preparação
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    
    # 2. Remoção das Foreign Keys (obrigatório antes de alterar o tipo da chave primária)
    remove_foreign_key :enderecos, :alunos
    remove_foreign_key :frequencia_alunos, :alunos, on_delete: :nullify # Use a restrição original
    remove_foreign_key :registros_de_notas, :alunos
    remove_foreign_key :avaliacoes_bimestrais, :alunos

    # 3. Conversão da Tabela ALUNOS (Chave Primária)
    # Crie uma nova coluna UUID temporária
    add_column :alunos, :uuid_id, :uuid, default: 'gen_random_uuid()', null: false
    
    # Preencha a coluna uuid_id:
    # Como o banco está vazio, o novo UUID será gerado pelo default, mas para um banco com dados faríamos um loop ou uma instrução SQL complexa.
    # Como o banco está VAZIO, a maneira mais segura é recriar a tabela.
    
    # -- Opção 3a: Recriar a tabela (Mais seguro quando VAZIA)
    # OBS: Se a branch developer for atualizada e a migração Devise for removida do arquivo AddDeviseToAluno.rb, 
    # teremos que reintroduzir as colunas Devise aqui.
    
    # Para ser simples, vamos fazer o seguinte (e torcer para que a developer não bagunce mais o create_alunos):
    
    # Remova e renomeie o ID:
    remove_column :alunos, :id
    rename_column :alunos, :uuid_id, :id
    execute "ALTER TABLE alunos ADD PRIMARY KEY (id);"
    
    # 4. Conversão das Foreign Keys
    change_column :enderecos, :aluno_id, :uuid, using: 'aluno_id::text::uuid'
    change_column :frequencia_alunos, :aluno_id, :uuid, using: 'aluno_id::text::uuid'
    change_column :registros_de_notas, :aluno_id, :uuid, using: 'aluno_id::text::uuid'
    change_column :avaliacoes_bimestrais, :aluno_id, :uuid, using: 'aluno_id::text::uuid'

    # 5. Adicionar as Foreign Keys de Volta
    add_foreign_key :enderecos, :alunos
    add_foreign_key :frequencia_alunos, :alunos, on_delete: :nullify
    add_foreign_key :registros_de_notas, :alunos
    add_foreign_key :avaliacoes_bimestrais, :alunos
  end
end