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
      # 🚨 Linha corrigida: use .find_by(id: ...) em vez de .find(...)
      user = registro.user_type.constantize.find_by(id: registro.user_id) 

      if user # Verifica se o usuário foi encontrado
        if user.valid_password?(password)
          # ... (Resto da lógica de login bem-sucedido)
          sign_in(user)
          UserMailer.login_alert(user).deliver_later
          flash[:notice] = "#{registro.user_type} logado com sucesso!"

          if user.is_a?(SuperAdmin)
            redirect_to dashboard_path
          else
            redirect_to root_path
          end
        else
          flash.now[:alert] = "Senha inválida"
          render :new
        end
      else
        # Novo tratamento: O EmailCadastro existe, mas o usuário (SuperAdmin, Professor, etc.) não.
        flash.now[:alert] = "Dados inconsistentes. Usuário não encontrado."
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
