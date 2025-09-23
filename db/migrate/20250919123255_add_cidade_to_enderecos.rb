class AddCidadeToEnderecos < ActiveRecord::Migration[7.1]
  def change
    add_reference :enderecos, :cidade, null: false, foreign_key: true
  end
end
