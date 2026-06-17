class AddOriginalEvaluationRefToAvaliacaoConfiguracao < ActiveRecord::Migration[7.1]
  def change
    # 1. Adiciona a referência (a coluna 'avaliacao_original_id')
    # O comando de linha gerou add_reference :avaliacoes_configuracoes, :avaliacao_original, null: false
    # Mude para esta sintaxe mais completa:
    add_reference :avaliacoes_configuracoes, :avaliacao_original, 
                  foreign_key: { to_table: :avaliacoes_configuracoes }, 
                  null: true

    # 2. Remove a coluna 'ordem'
    remove_column :avaliacoes_configuracoes, :ordem, :integer, if_exists: true
  end
end