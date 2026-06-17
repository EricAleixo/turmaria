class CreateTurmas < ActiveRecord::Migration[7.1]
  def change
    create_table :turmas do |t|
      t.string :nome
      t.integer :serie
      t.integer :turno

      t.timestamps
    end
  end
end
