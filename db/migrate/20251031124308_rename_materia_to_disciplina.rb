class RenameMateriaToDisciplina < ActiveRecord::Migration[7.1]
  def change
    rename_column :conteudos, :materia, :disciplina
    #Ex:- rename_column("admin_users", "pasword","hashed_pasword")
  end
end
