class RemoveNomeAndStatusFromAnoLetivo < ActiveRecord::Migration[7.1]
  def change
    remove_column :ano_letivos, :nome
    remove_column :ano_letivos, :status
  end
end
