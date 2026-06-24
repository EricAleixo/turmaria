class AddConceitoToRegistrosDeNotas < ActiveRecord::Migration[7.1]
  def change
    add_column :registros_de_notas, :conceito, :string
  end
end
