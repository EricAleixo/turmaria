# rails g migration CreateTransferencias
class CreateTransferencias < ActiveRecord::Migration[7.1]
  def change
    create_table :transferencias, id: :uuid do |t|
      t.references :aluno,         null: false, foreign_key: true, type: :uuid
      t.references :escola_origem, null: false, foreign_key: { to_table: :escolas }, type: :uuid
      t.references :escola_destino, null: false, foreign_key: { to_table: :escolas }, type: :uuid
      t.references :ano_letivo,    null: false, foreign_key: true
      t.references :historico_escolar, null: true, foreign_key: true, type: :uuid
      t.string  :motivo
      t.datetime :transferido_em, null: false
      t.timestamps
    end
  end
end