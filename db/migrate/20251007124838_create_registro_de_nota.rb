class CreateRegistroDeNota < ActiveRecord::Migration[7.1]
  def change
    create_table :registro_de_nota do |t|

      t.timestamps
    end
  end
end
