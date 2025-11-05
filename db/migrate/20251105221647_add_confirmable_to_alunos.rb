class AddConfirmableToAlunos < ActiveRecord::Migration[7.1]
  def change
    # Adiciona as colunas necessárias para o Devise Confirmable
    add_column :alunos, :confirmation_token, :string
    add_column :alunos, :confirmed_at, :datetime
    add_column :alunos, :confirmation_sent_at, :datetime
    add_column :alunos, :unconfirmed_email, :string # Only if using reconfirmable

    # Adiciona índice para busca rápida do token de confirmação
    add_index :alunos, :confirmation_token, unique: true

    # Garante que os registros existentes sejam tratados como confirmados
    # Nota: Em um ambiente de produção, esta linha deve ser removida
    # e a confirmação deve ser tratada com um processo de e-mail.
    # Aqui, garantimos que o 'db:seed' não falhe.
    Aluno.reset_column_information
    Aluno.update_all(confirmed_at: Time.current)
  end
end