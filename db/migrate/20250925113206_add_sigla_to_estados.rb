class AddSiglaToEstados < ActiveRecord::Migration[7.1]
  def change
    add_column :estados, :sigla, :string
  end
end
