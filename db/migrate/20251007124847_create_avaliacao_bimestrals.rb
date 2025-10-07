class CreateAvaliacaoBimestrals < ActiveRecord::Migration[7.1]
  def change
    create_table :avaliacao_bimestrals do |t|

      t.timestamps
    end
  end
end
