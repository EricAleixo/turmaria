class AddNomeToAnoLetivo < ActiveRecord::Migration[7.1]
  def change
    add_column :ano_letivos, :nome, :string
  end
end
