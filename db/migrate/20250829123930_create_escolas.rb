class CreateEscolas < ActiveRecord::Migration[7.1]
  def change
    create_table :escolas, id: :uuid do |t|
      t.string :nome

      t.timestamps
    end
    add_index :escolas, :nome, unique: true
  end
end
