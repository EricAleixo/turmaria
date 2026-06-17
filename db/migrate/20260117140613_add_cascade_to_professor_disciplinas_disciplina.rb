class AddCascadeToProfessorDisciplinasDisciplina < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :professor_disciplinas, :disciplinas
    add_foreign_key :professor_disciplinas, :disciplinas, on_delete: :cascade
  end
end
