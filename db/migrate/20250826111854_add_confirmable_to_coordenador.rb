class AddConfirmableToCoordenador < ActiveRecord::Migration[7.1]
  def change
    add_column :coordenadors, :confirmation_token, :string
    add_index :coordenadors, :confirmation_token, unique: true
    add_column :coordenadors, :confirmed_at, :datetime
    add_column :coordenadors, :confirmation_sent_at, :datetime
    add_column :coordenadors, :unconfirmed_email, :string
  end
end
