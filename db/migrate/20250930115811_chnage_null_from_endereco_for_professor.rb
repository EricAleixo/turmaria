class ChnageNullFromEnderecoForProfessor < ActiveRecord::Migration[7.1]
  def change
    change_column_null :professors, :endereco_id, true
  
  end
end
