class AddDeclaracaoAssinaturaImagemToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_column :escolas, :declaracao_assinatura_imagem, :text
  end
end
