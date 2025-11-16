class RemoveCorFromDisciplina < ActiveRecord::Migration[7.1]
  def change
    remove_column :disciplinas, :cor, :string
  end
end
