class AddEscolaToAdmins < ActiveRecord::Migration[7.1]
  def change
    add_reference :admins, :escola, null: true, foreign_key: true, type: :uuid
  end
end
