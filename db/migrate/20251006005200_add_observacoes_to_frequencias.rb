class AddObservacoesToFrequencias < ActiveRecord::Migration[7.1]
  def change
    add_column :frequencias, :observacoes, :text
  end
end
