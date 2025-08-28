class Devise::UnifiedRegistrationsController < Devise::RegistrationsController
  before_action :set_devise_mapping

  def new
    super
  end

  def create
    # Tenta criar o usuário em todas as roles, mas prioriza Professor
    user = Professor.new(sign_up_params)
    if user.save
      sign_in(:professor, user)
      redirect_to root_path, notice: "Cadastro realizado com sucesso"
      return
    end

    # Pode adicionar lógica para outras roles se necessário
    flash.now[:alert] = user.errors.full_messages.join(", ")
    render :new
  end

  private

  def set_devise_mapping
    request.env["devise.mapping"] = Devise.mappings[:professor]
  end

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
