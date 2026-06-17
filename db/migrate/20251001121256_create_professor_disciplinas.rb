class CreateProfessorDisciplinas < ActiveRecord::Migration[7.1]
  def change
    create_table :professor_disciplinas do |t|
      t.references :professor, null: false, foreign_key: true, type: :uuid
      t.references :disciplina, null: false, foreign_key: true

      t.timestamps
    end
  end
end
