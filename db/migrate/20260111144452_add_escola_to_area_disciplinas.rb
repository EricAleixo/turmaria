class AddEscolaToAreaDisciplinas < ActiveRecord::Migration[7.1]
  def change
    add_reference :area_disciplinas, :escola, null: false, foreign_key: true, type: :uuid
  end
end
