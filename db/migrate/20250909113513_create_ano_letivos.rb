class CreateAnoLetivos < ActiveRecord::Migration[7.1]
  def change
    create_table :ano_letivos do |t|
      t.integer :ano
      t.date :data_inicio
      t.date :data_fim
      t.integer :status

      t.timestamps
    end
  end
end
