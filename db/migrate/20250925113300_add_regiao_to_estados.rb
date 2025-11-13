class AddRegiaoToEstados < ActiveRecord::Migration[7.1]
  def change
    add_column :estados, :regiao, :string
  end
end
