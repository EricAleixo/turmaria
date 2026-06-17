class AddEscolaToConteudo < ActiveRecord::Migration[7.1]
  def change
    add_reference :conteudos, :escola, foreign_key: true, type: :uuid
  end
end
