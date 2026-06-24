class MakeValorNullableInRegistrosDeNotas < ActiveRecord::Migration[7.1]
  def change
    change_column_null :registros_de_notas, :valor, true
  end
end