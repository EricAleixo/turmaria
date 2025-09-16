class UserMailer < ApplicationMailer
  default from: ENV["EMAIL_USERNAME"]

  def login_alert(user)
    @user = user

  if @user.reset_password_token.nil? || @user.reset_password_sent_at.nil?
    @user.send_reset_password_instructions
    @user.reload
  end


  @reset_url = new_edit_user_password_url(
    reset_password_token: @user.reset_password_token,
    host: "localhost:3000"
  )

  mail(to: @user.email, subject: "Alerta de login - Turmaria")
  end
end
