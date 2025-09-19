class AddIndexesToAlunosAndTurmas < ActiveRecord::Migration[7.1]
  def change
    add_index :escolas, :alunos_count
    add_index :escolas, :turmas_count
  end
end
