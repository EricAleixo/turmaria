class RemoveNullableFromAreaDisciplina < ActiveRecord::Migration[7.1]
  def change
    remove_column :area_disciplinas, :nullable, :string
  end
end
