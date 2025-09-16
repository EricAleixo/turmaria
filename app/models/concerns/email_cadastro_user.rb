module EmailCadastroUser
  extend ActiveSupport::Concern

  included do
    has_many :email_cadastros, as: :user

    after_commit :create_email_cadastros
  end

  private

  def create_email_cadastros
    self.email_cadastros.create(email: self.email)
  end
end