class RemoveConteudoFromConteudo < ActiveRecord::Migration[7.1]
  def change
    remove_column :conteudos, :conteudo
  end
end
