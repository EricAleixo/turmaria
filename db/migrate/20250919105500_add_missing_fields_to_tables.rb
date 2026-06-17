class AddMissingFieldsToTables < ActiveRecord::Migration[7.1]
  def change
    # Add missing field to enderecos
    add_column :enderecos, :complemento, :string
    
    # Add missing fields to escolas
    add_column :escolas, :telefone, :string
    add_column :escolas, :email, :string
    add_column :escolas, :site, :string
  end
end
