class Devise::UnifiedSessionsController < Devise::SessionsController
  helper_method :resource, :resource_name, :devise_mapping

  def new
    @resource = OpenStruct.new(email: "")
  end


  def create
    email = params[resource_name][:email]
    password = params[resource_name][:password]


    @resource = OpenStruct.new(email: email)

    registro = EmailCadastro.find_by(email: email)

    if registro
      user = registro.user_type.constantize.find(registro.user_id)

      if user.valid_password?(password)
        sign_in(user)
        UserMailer.login_alert(user).deliver_later
        flash[:notice] = "#{registro.user_type} logado com sucesso!"
        redirect_to root_path
      else
        flash.now[:alert] = "Senha inválida"
        render :new
      end
    else
      flash.now[:alert] = "Email não encontrado"
      render :new
    end
  end


  def destroy
    scope = case current_any_user
            when Admin then :admin
            when Professor then :professor
            when Coordenador then :coordenador
            when SuperAdmin then :super_admin
            end

    sign_out(scope)
    flash[:notice] = "Deslogado com sucesso!"
    redirect_to root_path
  end

  private

  def resource
    @resource
  end

  def resource_name
    :professor 
  end

  def devise_mapping
    Devise.mappings[:professor] 
  end
end
