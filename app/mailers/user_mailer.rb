class UserMailer < ApplicationMailer
  default from: ENV["EMAIL_USERNAME"]

  def login_alert(user)
    @user = user

    # 1. Garante que o token de reset de senha exista
    if @user.reset_password_token.nil? || @user.reset_password_sent_at.nil?
      @user.send_reset_password_instructions
      @user.reload
    end

    # 2. Determina o scope Devise e a rota correta
    # O Devise cria rotas como: new_edit_aluno_password_url, new_edit_professor_password_url, etc.
    scope = @user.class.name.underscore # Ex: "Aluno" vira "aluno"

    # 3. Constrói o helper de URL dinamicamente
    # Ex: monta "new_edit_aluno_password_url"
    url_helper = "new_edit_#{scope}_password_url"

    # 4. Verifica se o helper existe (para segurança) e constrói a URL
    if respond_to?(url_helper)
      @reset_url = send(
        url_helper,
        reset_password_token: @user.reset_password_token,
        host: "localhost:3000"
      )
    else
      # Fallback caso a rota não seja encontrada (ajuste conforme a rota genérica que você deseja)
      @reset_url = root_url(host: "localhost:3000") 
    end

    mail(to: @user.email, subject: "Alerta de login - Turmaria")
  end
end
