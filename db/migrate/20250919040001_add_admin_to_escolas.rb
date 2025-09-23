class AddAdminToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_reference :escolas, :admin, null: true, foreign_key: true, type: :uuid
  end
end
