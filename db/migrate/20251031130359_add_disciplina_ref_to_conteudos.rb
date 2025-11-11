class AddDisciplinaRefToConteudos < ActiveRecord::Migration[7.1]
  def change
    add_reference :conteudos, :disciplina, foreign_key: true
  end
end
