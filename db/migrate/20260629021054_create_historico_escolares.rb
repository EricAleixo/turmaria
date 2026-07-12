class CreateHistoricoEscolares < ActiveRecord::Migration[7.1]
  def change
    create_table :historico_escolares, id: :uuid do |t|
      t.references :aluno,      null: false, foreign_key: true, type: :uuid
      t.references :escola,     null: false, foreign_key: true, type: :uuid
      t.references :ano_letivo, null: false, foreign_key: true

      t.string  :serie_turma,          null: false
      t.string  :turno
      t.string  :situacao_final,       null: false
      t.decimal :frequencia_geral_pct, precision: 5, scale: 2
      t.date    :data_conclusao
      t.text    :observacoes
      t.datetime :gerado_em

      t.timestamps
    end

    add_index :historico_escolares,
              [:aluno_id, :escola_id, :ano_letivo_id],
              unique: true,
              name: 'idx_historico_unico'
  end
end