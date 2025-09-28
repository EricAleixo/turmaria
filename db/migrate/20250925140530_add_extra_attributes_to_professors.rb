class AddExtraAttributesToProfessors < ActiveRecord::Migration[7.1]
  def change
    add_column :professors, :cpf, :string unless column_exists?(:professors, :cpf)
    add_column :professors, :data_nascimento, :date unless column_exists?(:professors, :data_nascimento)
    add_column :professors, :telefone, :string unless column_exists?(:professors, :telefone)
    add_column :professors, :foto, :string unless column_exists?(:professors, :foto)
    add_column :professors, :formacao, :string unless column_exists?(:professors, :formacao)
    add_column :professors, :tipo_professor, :string, default: "titular", null: false unless column_exists?(:professors, :tipo_professor)

    add_reference :professors, :escola, type: :uuid, foreign_key: true unless column_exists?(:professors, :escola_id)

    add_index :professors, :cpf, unique: true unless index_exists?(:professors, :cpf)
  end
end
