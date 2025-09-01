class AddTurmaToAluno < ActiveRecord::Migration[7.1]
  def change
    add_reference :alunos, :turma, null: false, foreign_key: true
  end
end
