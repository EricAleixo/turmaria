class AllowNullProfessorIdInFrequenciasAndConteudos < ActiveRecord::Migration[7.1]
  def change
    change_column_null :frequencias, :professor_id, true
    change_column_null :conteudos, :professor_id, true
  end
end
