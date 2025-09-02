class CreateEnderecos < ActiveRecord::Migration[7.1]
  def change
    create_table :enderecos do |t|
      t.string :logradouro
      t.string :numero
      t.string :bairro
      t.string :cidade
      t.string :estado
      t.string :cep
      t.references :aluno, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
