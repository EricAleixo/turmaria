class CreateCidades < ActiveRecord::Migration[7.1]
  def change
    create_table :cidades do |t|
      t.string :nome
      t.references :estado, null: false, foreign_key: true

      t.timestamps
    end
  end
end
