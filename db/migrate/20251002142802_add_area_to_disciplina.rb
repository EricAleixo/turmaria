class AddAreaToDisciplina < ActiveRecord::Migration[7.1]
  def change
    add_column :disciplinas, :area, :string
  end
end
