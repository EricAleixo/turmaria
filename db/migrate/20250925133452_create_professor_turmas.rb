class CreateProfessorTurmas < ActiveRecord::Migration[7.1]
  def change
    create_table :professor_turmas do |t|
      t.references :professor, type: :uuid, null: false, foreign_key: true
      t.references :turma, null: false, foreign_key: true
      
      t.timestamps
    end
  end
end
