class ModifyAlunoRelationships < ActiveRecord::Migration[7.1]
  def change
    # First add escola_id column as nullable
    add_reference :alunos, :escola, null: true, foreign_key: true, type: :uuid
    
    # Populate escola_id from existing turma relationships
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE alunos 
          SET escola_id = turmas.escola_id 
          FROM turmas 
          WHERE alunos.turma_id = turmas.id
        SQL
      end
    end
    
    # Now make escola_id NOT NULL since all records should have values
    change_column_null :alunos, :escola_id, false
    
    # Make turma_id optional
    change_column_null :alunos, :turma_id, true
    
    # Add indexes for better performance (only if they don't exist)
    add_index :alunos, [:escola_id, :turma_id], if_not_exists: true
  end
end
