class AddPolymorphicToEmailCadastros < ActiveRecord::Migration[7.1]
  def change
    add_reference :email_cadastros, :user, polymorphic: true, null: false, type: :uuid
  end
end
