# db/migrate/20251117130105_correct_conteudo_bimestre_and_add_tipo.rb
class CorrectConteudoBimestreAndAddTipo < ActiveRecord::Migration[7.1]
  def change
    # 1. Altera o tipo do bimestre de STRING para INTEGER, com conversão
    change_column :conteudos, :bimestre, :integer, using: 'bimestre::integer', default: 1

    # 2. Adiciona o novo campo 'tipo' (0: material, 1: atividade).
    add_column :conteudos, :tipo, :integer, default: 0, null: false
  end
end