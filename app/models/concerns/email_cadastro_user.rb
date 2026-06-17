module EmailCadastroUser
  extend ActiveSupport::Concern

  included do
    has_one :email_cadastro, as: :user, dependent: :destroy

    # Sincroniza após criar ou atualizar o email
    after_commit :sync_email_cadastro, on: [:create, :update], if: :saved_change_to_email?

    # Deleta o EmailCadastro quando o usuário for destruído
    after_destroy :destroy_email_cadastro
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

  def destroy_email_cadastro
    email_cadastro&.destroy
  end
end
