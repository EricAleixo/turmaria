class CreateEmailCadastros < ActiveRecord::Migration[7.1]
  def change
    create_table :email_cadastros, id: :uuid do |t|
      t.string :email

      t.timestamps
    end

    add_index :email_cadastros, :email, unique: true
    
  end
end
