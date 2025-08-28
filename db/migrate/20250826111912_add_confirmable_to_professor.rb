class AddConfirmableToProfessor < ActiveRecord::Migration[7.1]
  def change
    add_column :professors, :confirmation_token, :string
    add_index :professors, :confirmation_token, unique: true
    add_column :professors, :confirmed_at, :datetime
    add_column :professors, :confirmation_sent_at, :datetime
    add_column :professors, :unconfirmed_email, :string
  end
end
