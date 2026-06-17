class AddAreaToDisciplina < ActiveRecord::Migration[7.1]
  def change

    add_reference :disciplinas, :area_disciplina, foreign_key: true

  end
end
