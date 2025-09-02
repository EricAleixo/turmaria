class ChangeAlunoUuidForId < ActiveRecord::Migration[7.1]
  def change
    # 1. remove foreign key constraint from enderecos
    remove_foreign_key :enderecos, :alunos if foreign_key_exists?(:enderecos, :alunos)
    
    # 2. create mapping table to preserve UUID -> bigint relationships
    create_table :aluno_id_mapping do |t|
      t.uuid :old_uuid
      t.bigint :new_id
    end
    
    # 3. cria tabela temporária com id bigint
    create_table :alunos_temp do |t|
      t.string :nome
      t.date :data_nascimento
      t.references :turma, null: false, foreign_key: true, type: :bigint

      t.timestamps
    end

    # 4. copia os dados e cria mapeamento
    execute <<-SQL
      INSERT INTO alunos_temp (nome, data_nascimento, turma_id, created_at, updated_at)
      SELECT nome, data_nascimento, turma_id, created_at, updated_at FROM alunos;
    SQL
    
    # 5. create mapping between old UUIDs and new bigint IDs
    execute <<-SQL
      INSERT INTO aluno_id_mapping (old_uuid, new_id)
      SELECT a.id, at.id 
      FROM alunos a
      JOIN alunos_temp at ON (a.nome = at.nome AND a.data_nascimento = at.data_nascimento AND a.turma_id = at.turma_id);
    SQL

    # 6. add new bigint column to enderecos
    add_column :enderecos, :new_aluno_id, :bigint
    
    # 7. update enderecos to use new bigint IDs
    execute <<-SQL
      UPDATE enderecos 
      SET new_aluno_id = (
        SELECT aim.new_id 
        FROM aluno_id_mapping aim 
        WHERE aim.old_uuid = enderecos.aluno_id
      );
    SQL
    
    # 8. remove old UUID column and rename new column
    remove_column :enderecos, :aluno_id
    rename_column :enderecos, :new_aluno_id, :aluno_id

    # 9. apaga a antiga tabela alunos e mapping
    drop_table :alunos
    drop_table :aluno_id_mapping

    # 10. renomeia a nova
    rename_table :alunos_temp, :alunos
    
    # 11. re-add foreign key constraint
    add_foreign_key :enderecos, :alunos
  end
end
