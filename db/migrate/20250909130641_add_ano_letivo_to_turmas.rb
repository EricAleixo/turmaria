class AddAnoLetivoToTurmas < ActiveRecord::Migration[7.1]
  def change
    add_reference :turmas, :ano_letivo, null: false, foreign_key: true
  end
end
