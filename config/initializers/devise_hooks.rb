Warden::Manager.after_authentication do |user, auth, opts|
  Rails.logger.info "=== Hook disparou para #{user.class.name} #{user.email} ==="

  allowed_models = [Admin, Professor, Coordenador, Superadmin]
  if user.respond_to?(:email) && user.email.present?
    Rails.logger.info "Enfileirando e-mail de login alert..."
    UserMailer.login_alert(user).deliver_later
  end
end