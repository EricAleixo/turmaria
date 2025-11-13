class AddCidadeToAlunos < ActiveRecord::Migration[7.1]
  def change
    add_reference :alunos, :cidade, null: false, foreign_key: true
  end
end
