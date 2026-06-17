class CreateAreaDisciplina < ActiveRecord::Migration[7.1]
  def change
    create_table :area_disciplinas do |t|
      t.string :nome, null: false
      t.string :cor, null: false

      t.timestamps
    end
  end
end
