# db/migrate/20251007123412_create_registros_de_notas.rb

class CreateRegistrosDeNotas < ActiveRecord::Migration[7.1]
  def change
    create_table :registros_de_notas do |t|
      # Referência do aluno está OK
      t.references :aluno, null: false, foreign_key: true, type: :bigint

      # CORREÇÃO AQUI: Removemos foreign_key: true.
      # Usamos 'avaliacao_configuracao' como nome da coluna.
      t.bigint :avaliacao_configuracao_id, null: false

      t.decimal :valor, precision: 4, scale: 2, null: false
      t.date :data_registro

      t.timestamps
    end
    
    # Índice para garantir a unicidade
    add_index :registros_de_notas, 
              [:aluno_id, :avaliacao_configuracao_id], 
              unique: true, 
              name: 'idx_unique_nota_registro_valor'
              
    # CHAVE ESTRANGEIRA MANUALMENTE ADICIONADA:
    # Agora sim, usamos o :to_table para apontar para a tabela correta
    add_foreign_key :registros_de_notas, 
                    :avaliacoes_configuracoes, 
                    column: :avaliacao_configuracao_id
  end
end
