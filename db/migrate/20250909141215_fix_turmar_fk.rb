class FixTurmarFk < ActiveRecord::Migration[7.1]
  def change

    remove_foreign_key :turmas, :ano_letivos

    change_column :turmas, :ano_letivo_id, :bigint, null: false

    add_foreign_key :turmas, :ano_letivos

    remove_foreign_key :turmas, :escolas
    add_foreign_key :turmas, :escolas
  end
end
