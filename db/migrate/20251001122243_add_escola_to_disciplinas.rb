class AddEscolaToDisciplinas < ActiveRecord::Migration[7.1]
  def change
    add_reference :disciplinas, :escola, null: false, foreign_key: true, type: :uuid
  end
end
