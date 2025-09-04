class AddCnpjToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_column :escolas, :cnpj, :string
    add_index :escolas, :cnpj, unique: true
  end
end
