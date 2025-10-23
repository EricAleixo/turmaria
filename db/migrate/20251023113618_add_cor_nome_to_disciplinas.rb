class AddCorNomeToDisciplinas < ActiveRecord::Migration[7.1]
  def change
    add_column :disciplinas, :cor_nome, :string
  end
end
