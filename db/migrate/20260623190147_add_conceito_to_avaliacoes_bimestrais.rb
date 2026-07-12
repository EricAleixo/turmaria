class AddConceitoToAvaliacoesBimestrais < ActiveRecord::Migration[7.1]
  def change
    add_column :avaliacoes_bimestrais, :conceito, :integer
  end
end