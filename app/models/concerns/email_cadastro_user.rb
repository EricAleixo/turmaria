module EmailCadastroUser
  extend ActiveSupport::Concern

  included do
    has_one :email_cadastro, as: :user, dependent: :destroy

    after_commit :sync_email_cadastro, if: :saved_change_to_email?
  end

  private

  def sync_email_cadastro
    return if email.blank?

    if email_cadastro
      email_cadastro.update!(email: email)
    else
      create_email_cadastro!(email: email)
    end
  end
end
