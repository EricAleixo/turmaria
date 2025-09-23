class RemoveCidadeEstadoFromEnderecosAddCidadeRef < ActiveRecord::Migration[7.1]
  def change
    
    remove_column :enderecos, :cidade, :string if column_exists?(:enderecos, :cidade)
    remove_column :enderecos, :estado, :string if column_exists?(:enderecos, :estado)

  end
end
