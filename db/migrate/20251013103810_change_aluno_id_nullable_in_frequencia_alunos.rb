class ChangeAlunoIdNullableInFrequenciaAlunos < ActiveRecord::Migration[7.1]
  def change
    change_column_null :frequencia_alunos, :aluno_id, true
  end
end
