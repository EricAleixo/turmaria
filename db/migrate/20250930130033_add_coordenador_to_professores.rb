class AddCoordenadorToProfessores < ActiveRecord::Migration[7.1]
  def change
    add_reference :professors, :coordenador, foreign_key: { to_table: :professors }, null: true, type: :uuid
  end
end
