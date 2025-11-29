class CleanConteudosBimestre < ActiveRecord::Migration[7.1]
  def up
    # Converte string vazia para NULL
    execute <<~SQL
      UPDATE conteudos
      SET bimestre = NULL
      WHERE bimestre = '';
    SQL
  end

  def down
  end
end
