class CreateTurmaDisciplinas < ActiveRecord::Migration[7.1] # Sua versão pode ser diferente
  def change
    create_table :turma_disciplinas do |t|
      # Adiciona a coluna turma_id e configura como foreign key
      t.references :turma, null: false, foreign_key: true 
      
      # Adiciona a coluna disciplina_id e configura como foreign key
      t.references :disciplina, null: false, foreign_key: true

      t.timestamps
    end
    
    # É importante garantir que não haja duplicatas
    add_index :turma_disciplinas, [:turma_id, :disciplina_id], unique: true
  end
end