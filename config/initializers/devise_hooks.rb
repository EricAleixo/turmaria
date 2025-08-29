Warden::Manager.after_authentication do |user, auth, opts|
 

  allowed_models = [Admin, Professor, Coordenador, SuperAdmin]
  if user.respond_to?(:email) && user.email.present?
    UserMailer.login_alert(user).deliver_later
  end
end