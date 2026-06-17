class AddDisciplinaToFrequencias < ActiveRecord::Migration[7.1]
  def change
    add_reference :frequencias, :disciplina, null: false, foreign_key: true
  end
end
