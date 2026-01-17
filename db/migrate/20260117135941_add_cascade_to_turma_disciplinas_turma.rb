class AddCascadeToTurmaDisciplinasTurma < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :turma_disciplinas, :turmas
    add_foreign_key :turma_disciplinas, :turmas, on_delete: :cascade
  end
end
