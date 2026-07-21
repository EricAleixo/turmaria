class AddDeclaracaoFieldsToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_column :escolas, :declaracao_cabecalho, :text
    add_column :escolas, :declaracao_corpo, :text
    add_column :escolas, :declaracao_assinatura_cargo, :string
    add_column :escolas, :declaracao_assinatura_nome, :string
  end
end
