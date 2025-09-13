class AddNumeroBimestreToAnoLetivo < ActiveRecord::Migration[7.1]
  def change
    add_column :ano_letivos, :numero_bimestre, :integer
  end
end
