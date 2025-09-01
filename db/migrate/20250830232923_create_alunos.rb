class CreateAlunos < ActiveRecord::Migration[7.1]
  def change
    create_table :alunos, id: :uuid do |t|
      t.string :nome
      t.date :data_nascimento

      t.timestamps
    end
  end
end
