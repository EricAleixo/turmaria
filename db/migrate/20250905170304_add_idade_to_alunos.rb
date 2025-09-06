class AddIdadeToAlunos < ActiveRecord::Migration[7.1]
  def change
    add_column :alunos, :idade, :integer
  end
end
