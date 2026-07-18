# db/migrate/20260718135646_create_declaracoes.rb
class CreateDeclaracoes < ActiveRecord::Migration[7.1]
  def change
    create_table :declaracoes do |t|
      t.references :aluno,      null: false, type: :uuid,   foreign_key: true
      t.references :escola,     null: false, type: :uuid,   foreign_key: true
      t.references :turma,      null: false, type: :bigint, foreign_key: true
      t.references :ano_letivo, null: false, type: :bigint, foreign_key: true

      t.string :codigo_autenticidade, null: false
      t.string :token, null: false
      t.datetime :emitido_em, null: false
      t.jsonb :dados_snapshot, null: false, default: {}
      t.boolean :ativa, null: false, default: true

      t.timestamps
    end

    add_index :declaracoes, :codigo_autenticidade, unique: true
    add_index :declaracoes, :token, unique: true
  end
end