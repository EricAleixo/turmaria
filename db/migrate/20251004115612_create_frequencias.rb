class CreateFrequencias < ActiveRecord::Migration[7.1]
  def change
    create_table :frequencias do |t|
      t.references :turma, null: false, foreign_key: true
      t.references :professor, null: false, foreign_key: { to_table: :professors }, type: :uuid
      t.date :data_aula, null: false
      t.text :conteudo_trabalhado
      t.timestamps
    end

    create_table :frequencia_alunos do |t|
      t.references :frequencia, null: false, foreign_key: { to_table: :frequencias }
      t.references :aluno, null: false, foreign_key: true
      t.string :status, null: false, default: 'presente' # presente, falta, justificada
      t.text :observacoes
      t.timestamps
    end

    add_index :frequencias, [:turma_id, :data_aula], unique: true
    add_index :frequencia_alunos, [:frequencia_id, :aluno_id], unique: true
  end
end
