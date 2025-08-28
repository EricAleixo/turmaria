class UserMailer < ApplicationMailer
  default from: "leonardopereiracavalcante2025@gmail.com"

  def login_alert (user)
    @user= user
    @user_type = user.class.name
    @reset_password_url = generate_reset_password_url(@user)

    mail(
      to: @user.email,
      subject: "Turmaria - Alerta de login detectado"
    )
  end

  private

  def generate_reset_password_url(user)
    
    raw, enc = Devise.token_generator.generate(user.class, :reset_password_token)

    user.reset_password_token = enc 
    user.reset_password_sent_at = Time.now.utc
    user.save(validate:false)

    Rails.application.routes.url_helpers.send(
      "edit_#{user.model_name.singular}_password_url",
      reset_password_token:raw,
      host: Rails.application.config.action_mailer.default_url_options[:host],
      port: Rails.application.config.action_mailer.default_url_options[:port]
    )
  end
end
