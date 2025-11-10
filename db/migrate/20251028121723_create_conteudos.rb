class CreateConteudos < ActiveRecord::Migration[7.1]
  def change
    create_table :conteudos do |t|
      t.string :titulo
      t.string :materia
      t.string :bimestre
      t.text :descricao
      t.references :professor, null: false, foreign_key: true, type: :uuid
      t.text :conteudo

      t.timestamps
    end
  end
end
