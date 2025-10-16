
class AllowNullForeignKeysInEnderecos < ActiveRecord::Migration[7.1]
  def change
    # Permite que a coluna aluno_id aceite NULLs na tabela enderecos
    change_column_null :enderecos, :aluno_id, true
    
    # Permite que a coluna escola_id aceite NULLs
    change_column_null :enderecos, :escola_id, true
    
    # Permite que a coluna professor_id aceite NULLs
    change_column_null :enderecos, :professor_id, true
    
    # Permite que a coluna cidade_id aceite NULLs
    change_column_null :enderecos, :cidade_id, true
  end
end
