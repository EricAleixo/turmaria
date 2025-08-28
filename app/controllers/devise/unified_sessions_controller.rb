class Devise::UnifiedSessionsController < Devise::SessionsController
  before_action :set_devise_mapping

  def new
    super
  end

  def create
    user = find_user_by_email(params[:user][:email])

    if user && user.valid_password?(params[:user][:password])
      sign_in(determine_scope(user), user)
      redirect_to root_path, notice: "Login realizado com sucesso"
    else
      flash.now[:alert] = "Email ou senha inválidos"
      render :new
    end
  end

  def destroy
    sign_out_all_scopes
    redirect_to root_path, notice: "Logout realizado!"
  end

  private

  def set_devise_mapping
    request.env["devise.mapping"] = Devise.mappings[:professor]
  end

  def find_user_by_email(email)
    [Professor, Coordenador, Admin, SuperAdmin].each do |model|
      user = model.find_by(email: email)
      return user if user
    end
    nil
  end

  def determine_scope(user)
    user.class.name.underscore.to_sym
  end
end
