class AddTipoAvaliacaoToTurmas < ActiveRecord::Migration[7.1]
  def change
    add_column :turmas, :tipo_avaliacao, :integer, null: false, default: 0
    add_index  :turmas, :tipo_avaliacao
  end
end