class AddCascadeToAvaliacoesConfiguracoesTurma < ActiveRecord::Migration[7.1]
  def change
    remove_foreign_key :avaliacoes_configuracoes, :turmas
    add_foreign_key :avaliacoes_configuracoes, :turmas, on_delete: :cascade
  end
end
