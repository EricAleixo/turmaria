class RecreateEscolasWithBigint < ActiveRecord::Migration[7.1]
  def change
    create_table :escolas_temp do |t|
      t.string :nome

      t.timestamps
    end
    add_index :escolas_temp, :nome, unique: true

    drop_table :escolas
    rename_table :escolas_temp, :escolas
  end

  def down
    drop_table :escolas
  end
end
