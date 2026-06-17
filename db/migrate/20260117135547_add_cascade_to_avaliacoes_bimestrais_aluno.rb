class AddCascadeToAvaliacoesBimestraisAluno < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :avaliacoes_bimestrais, :alunos
    add_foreign_key :avaliacoes_bimestrais, :alunos, on_delete: :cascade
  end
end
