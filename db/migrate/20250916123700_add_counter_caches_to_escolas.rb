class AddCounterCachesToEscolas < ActiveRecord::Migration[7.1]
  def change
    add_column :escolas, :turmas_count, :integer, default: 0
    add_column :escolas, :alunos_count, :integer, default: 0
  end
end
