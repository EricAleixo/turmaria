class ChangeAlunoUuidForId < ActiveRecord::Migration[7.1]
  def change
    # 1. cria tabela temporária com id bigint
    create_table :alunos_temp do |t|
      t.string :nome
      t.date :data_nascimento
      t.references :turma, null: false, foreign_key: true, type: :bigint

      t.timestamps
    end

    # 2. copia os dados (se existirem)
    execute <<-SQL
      INSERT INTO alunos_temp (nome, data_nascimento, turma_id, created_at, updated_at)
      SELECT nome, data_nascimento, turma_id, created_at, updated_at FROM alunos;
    SQL

    # 3. apaga a antiga
    drop_table :alunos

    # 4. renomeia a nova
    rename_table :alunos_temp, :alunos
  end
end
