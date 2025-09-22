class Cidade < ApplicationRecord
  belongs_to :estado
  has_many :enderecos

  def nome_com_estado
    "#{nome} - #{estado.nome}"
  end
end