class AddEscolaToAnoLetivos < ActiveRecord::Migration[7.1]
  def change
    add_reference :ano_letivos, :escola, null: false, type: :uuid,  foreign_key: true
  end
end
