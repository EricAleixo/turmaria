class RemoveDisciplinaFromConteudo < ActiveRecord::Migration[7.1]
  def change
    remove_column :conteudos, :disciplina
  end
end
