class AddDeviseToAluno < ActiveRecord::Migration[7.1]
  def change
    add_column :alunos, :matricula, :string
    add_index :alunos, :matricula, unique: true
    add_column :alunos, :encrypted_password, :string
    add_column :alunos, :reset_password_token, :string
    add_column :alunos, :reset_password_sent_at, :datetime
    add_column :alunos, :remember_created_at, :datetime
  end
end
