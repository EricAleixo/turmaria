class CreateAvaliacoesConfiguracoes < ActiveRecord::Migration[7.1]
  def change
    create_table :avaliacoes_configuracoes do |t|
      # Referências obrigatórias
      t.references :turma, null: false, foreign_key: true, type: :bigint
      t.references :disciplina, null: false, foreign_key: true, type: :bigint

      # Campos para a configuração da avaliação
      t.integer :bimestre, null: false
      t.string :nome, null: false 
      # CORRIGIDO: Adicionando o default: false aqui no arquivo.
      t.boolean :is_recuperacao, default: false, null: false 
      t.integer :ordem, null: false 

      t.timestamps
    end
    
    # Índice para garantir que não haja duas colunas de nota com o mesmo nome no mesmo bimestre/disciplina/turma
    add_index :avaliacoes_configuracoes, 
              [:turma_id, :disciplina_id, :bimestre, :nome], 
              unique: true, 
              name: 'idx_unique_avaliacao_config'
  end
end
