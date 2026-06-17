class RemoveAreaFromDisciplina < ActiveRecord::Migration[7.1]
  def change
    remove_column :disciplinas, :area, :string if column_exists?(:disciplinas, :area)
  end
end
