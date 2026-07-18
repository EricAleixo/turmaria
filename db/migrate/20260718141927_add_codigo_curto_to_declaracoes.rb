class AddCodigoCurtoToDeclaracoes < ActiveRecord::Migration[7.1]
  def change
    add_column :declaracoes, :codigo_curto, :string
    add_index :declaracoes, :codigo_curto, unique: true
  end
end