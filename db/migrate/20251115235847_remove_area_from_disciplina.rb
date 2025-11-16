class RemoveAreaFromDisciplina < ActiveRecord::Migration[7.1]
  def change
    remove_column :disciplinas, :area, :string
  end
end
