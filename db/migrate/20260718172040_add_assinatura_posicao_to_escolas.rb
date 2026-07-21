
class AddAssinaturaPosicaoToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_column :escolas, :declaracao_assinatura_pos_x, :float
    add_column :escolas, :declaracao_assinatura_pos_y, :float
  end
end
