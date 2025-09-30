class AddEnderecoToProfessor < ActiveRecord::Migration[7.1]
  def change
    add_reference :professors, :endereco, null: false, foreign_key: true
  end
end
