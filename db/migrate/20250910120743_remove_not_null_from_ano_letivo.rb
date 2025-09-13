class RemoveNotNullFromAnoLetivo < ActiveRecord::Migration[7.1]
  def change
    change_column_null :ano_letivos, :escola_id, true
    #Ex:- change_column("admin_users", "email", :string, :limit =>25)
  end
end
