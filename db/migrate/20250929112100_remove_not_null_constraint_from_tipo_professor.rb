class RemoveNotNullConstraintFromTipoProfessor < ActiveRecord::Migration[7.1]
  def change
    change_column_null :professors, :tipo_professor, true
  end
end

