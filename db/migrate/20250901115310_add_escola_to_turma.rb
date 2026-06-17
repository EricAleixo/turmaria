class AddEscolaToTurma < ActiveRecord::Migration[7.1]
  def change
    add_reference :turmas, :escola, null: false, foreign_key: true, type: :uuid
  end
end
