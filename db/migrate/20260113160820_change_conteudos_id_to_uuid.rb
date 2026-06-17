class ChangeConteudosIdToUuid < ActiveRecord::Migration[7.1]
  def change
    # Remove a coluna id antiga
    remove_column :conteudos, :id

    # Adiciona id como UUID e primary key
    add_column :conteudos, :id, :uuid, default: 'gen_random_uuid()', null: false, primary_key: true
  end
end