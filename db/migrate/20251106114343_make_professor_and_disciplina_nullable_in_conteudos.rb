class MakeProfessorAndDisciplinaNullableInConteudos < ActiveRecord::Migration[7.1]
  def change
    change_column_null :conteudos, :professor_id, true
    change_column_null :conteudos, :disciplina_id, true
  end
end
