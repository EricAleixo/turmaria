class AllowNullOnAlunoFields < ActiveRecord::Migration[7.1]
  def change
    # Campos que você quer tornar OPCIONAIS:
    change_column_null :alunos, :data_nascimento, true
    change_column_null :alunos, :cpf, true
    change_column_null :alunos, :rg, true
    change_column_null :alunos, :email, true
    change_column_null :alunos, :telefone, true
    change_column_null :alunos, :responsavel_1, true
    change_column_null :alunos, :telefone_responsavel_1, true
    change_column_null :alunos, :responsavel_2, true
    change_column_null :alunos, :telefone_responsavel_2, true

    # Certifique-se de que a FK escola_id é NOT NULL (deve ser obrigatória)
    # Se você precisar que escola_id seja opcional, mude para:
    # change_column_null :alunos, :escola_id, true 
    # Mas recomendo deixar como NOT NULL já que é preenchido pelo controller.
  end
end