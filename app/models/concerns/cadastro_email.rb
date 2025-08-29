module CadastroEmail
  extend ActiveSupport::Concern

  included do 
    after_create :adicionar_email
  end

  private

  def adicionar_email
    EmailCadastro.find_or_create_by(email: self.email)
  end
end