class FixAdminEscolaRelationshipAndAddTipo < ActiveRecord::Migration[7.1]
  def change
    # Remove a referência circular - admin não deve ter escola_id
    # O relacionamento correto é: Admin has_many :escolas, Escola belongs_to :admin
    remove_reference :admins, :escola, foreign_key: true, type: :uuid
    
    # Adiciona o campo tipo para escolas (pública ou privada)
    add_column :escolas, :tipo, :string, default: 'publica', null: false
    add_index :escolas, :tipo
  end
end
