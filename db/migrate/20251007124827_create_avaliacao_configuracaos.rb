class CreateAvaliacaoConfiguracaos < ActiveRecord::Migration[7.1]
  def change
    create_table :avaliacao_configuracaos do |t|

      t.timestamps
    end
  end
end
