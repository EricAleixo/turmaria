class AddMarkdownToConteudo < ActiveRecord::Migration[7.1]
  def change
    add_column :conteudos, :markdown, :text
  end
end
