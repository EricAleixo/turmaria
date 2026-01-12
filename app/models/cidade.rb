class Cidade < ApplicationRecord
  belongs_to :estado
  has_many :enderecos, dependent: :destroy
  has_many :alunos

  def nome_com_estado
    "#{nome} - #{estado.nome}"
  end
end