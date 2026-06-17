class ChangeNecessidadesEspeciaisTipoToTextArrayInAlunos < ActiveRecord::Migration[7.1]
  def up
    change_column :alunos, :necessidades_especiais_tipo, :text, array: true, default: [], using: 'ARRAY[necessidades_especiais_tipo]'
  end

  def down
    change_column :alunos, :necessidades_especiais_tipo, :string
  end
end
