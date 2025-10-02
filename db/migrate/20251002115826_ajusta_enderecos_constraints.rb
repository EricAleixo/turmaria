class AjustaEnderecosConstraints < ActiveRecord::Migration[7.1]
  def change
    change_column_null :enderecos, :professor_id, true
    change_column_null :enderecos, :aluno_id, true
  end
end
