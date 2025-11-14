class RemoveNullableFromAreaDisciplina < ActiveRecord::Migration[7.1]
  def change
    if column_exists?(:area_disciplinas, :nullable)
      remove_column :area_disciplinas, :nullable, :string
    end
  end
end
