class AddIndexesForBuscaConteudo < ActiveRecord::Migration[7.1]
  def change
    # Índice na tabela escolas para busca por nome (case-insensitive)
    add_index :escolas, "LOWER(nome)", name: "index_escolas_on_lower_nome"

    add_index :conteudos, :bimestre
    
    # Índice composto para acelerar consultas que filtram por escola, disciplina e professor juntos
    add_index :conteudos, [:escola_id, :disciplina_id, :professor_id], name: "index_conteudos_on_escola_disciplina_professor"
  end
end
