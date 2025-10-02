class RemoveEnderecoFromProfessores < ActiveRecord::Migration[7.1]
  def change
    remove_reference :professors, :endereco, null: false, foreign_key: true
  end
end
