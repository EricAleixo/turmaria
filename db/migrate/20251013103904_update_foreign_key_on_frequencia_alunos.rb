class UpdateForeignKeyOnFrequenciaAlunos < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :frequencia_alunos, :alunos
    add_foreign_key :frequencia_alunos, :alunos, on_delete: :nullify
  end
end
