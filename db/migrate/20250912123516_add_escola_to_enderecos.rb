class AddEscolaToEnderecos < ActiveRecord::Migration[7.1]
  def change
    add_reference :enderecos, :escola, null: false, foreign_key: true, type: :uuid
  end
end
