class CreateProfessores < ActiveRecord::Migration[7.1]
  def change
    create_table :professores, id: :uuid do |t|
      t.string :nome, null: false
      t.string :cpf, null: false
      t.string :email, null: false
      t.date :data_nascimento
      t.string :telefone
      t.string :foto
      t.string :formacao
      t.string :tipo_professor, default: "titular"

      t.timestamps
    end

    add_index :professores, :cpf, unique: true
    add_index :professores, :email, unique: true
  end
end
