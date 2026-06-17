class ChangeCidadeIdOnAlunosToAllowNull < ActiveRecord::Migration[7.1]
  def change
    # Isto instrui o banco de dados a permitir valores nulos (NULL)
    change_column_null :alunos, :cidade_id, true
  end
end