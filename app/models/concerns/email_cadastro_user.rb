module EmailCadastroUser
  extend ActiveSupport::Concern

  included do
    # Garante que o usuário (SuperAdmin, Professor, etc.) tem a associação de volta.
    # Nota: Em muitos casos, você não precisa desta linha se a associação for apenas para Devise/login
    # has_many :email_cadastros, as: :user, dependent: :destroy 
    
    # Usamos after_commit para garantir que o 'id' do objeto já foi persistido (essencial para UUIDs)
    after_commit :ensure_email_cadastro_is_present
  end

  private

  def ensure_email_cadastro_is_present
    # Procura um registro existente pelo e-mail ou o inicializa.
    # O user_type e user_id são definidos explicitamente para garantir que a ponte funcione.
    EmailCadastro.find_or_initialize_by(email: self.email).tap do |ec|
      ec.user_type = self.class.name  # Ex: 'SuperAdmin', 'Professor'
      ec.user_id = self.id            # O UUID do usuário
      ec.save!
    end
  end
end