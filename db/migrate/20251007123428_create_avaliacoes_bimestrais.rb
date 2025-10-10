# db/migrate/XXXXXXXXXXXXXX_create_avaliacoes_bimestrais.rb
class CreateAvaliacoesBimestrais < ActiveRecord::Migration[7.1]
  def change
    create_table :avaliacoes_bimestrais do |t|
      # Referências (Estas já pluralizam corretamente para alunos, turmas, disciplinas)
      t.references :aluno, null: false, foreign_key: true, type: :bigint
      t.references :turma, null: false, foreign_key: true, type: :bigint
      t.references :disciplina, null: false, foreign_key: true, type: :bigint

      t.integer :bimestre, null: false
      t.decimal :nota_bimestre_final, precision: 4, scale: 2

      t.timestamps
    end
    
    add_index :avaliacoes_bimestrais, 
              [:aluno_id, :turma_id, :disciplina_id, :bimestre], 
              unique: true, 
              name: 'idx_unique_avaliacao_bimestral'
  end
end