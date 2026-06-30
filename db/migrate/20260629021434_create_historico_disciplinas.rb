class CreateHistoricoDisciplinas < ActiveRecord::Migration[7.1]
  def change
    create_table :historico_disciplinas, id: :uuid do |t|
      t.references :historico_escolar,
             null: false,
             foreign_key: { to_table: :historico_escolares },
             type: :uuid

      t.string :disciplina_nome, null: false

      t.decimal :nota_b1, precision: 4, scale: 2
      t.decimal :nota_b2, precision: 4, scale: 2
      t.decimal :nota_b3, precision: 4, scale: 2
      t.decimal :nota_b4, precision: 4, scale: 2
      t.decimal :media_final, precision: 4, scale: 2

      t.string :conceito_b1
      t.string :conceito_b2
      t.string :conceito_b3
      t.string :conceito_b4
      t.string :conceito_final

      t.integer :aulas_dadas,  default: 0
      t.integer :total_faltas, default: 0

      t.timestamps
    end
  end
end