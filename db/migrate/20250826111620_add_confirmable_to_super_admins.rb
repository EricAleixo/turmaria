class AddConfirmableToSuperAdmins < ActiveRecord::Migration[7.1]
  def change
    add_column :super_admins, :confirmation_token, :string
    add_index :super_admins, :confirmation_token, unique: true
    add_column :super_admins, :confirmed_at, :datetime
    add_column :super_admins, :confirmation_sent_at, :datetime
    add_column :super_admins, :unconfirmed_email, :string
  end
end
