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

          redirect_to after_sign_in_path_for(user)
          return

          if user.is_a?(SuperAdmin)
            redirect_to dashboard_path
          else
            redirect_to root_path
          end
        else
          flash.now[:alert] = "Senha inválida"
          render :new
          return
        end
      else
        # Novo tratamento: O EmailCadastro existe, mas o usuário (SuperAdmin, Professor, etc.) não.
        flash.now[:alert] = "Dados inconsistentes. Usuário não encontrado."
        render :new
        return
      end
    else
      flash.now[:alert] = "Email não encontrado"
      render :new
      return
    end
  end
 

  # Devise::UnifiedSessionsController#destroy

  def destroy
    # 1. Obtém o nome do escopo atual para o flash message
    current_scope = current_any_user.class.to_s.underscore.to_sym if current_any_user.present?

    # 2. Força o sign out de TODOS os escopos conhecidos, independentemente de quem está "current"
    sign_out(:aluno)
    sign_out(:professor)
    sign_out(:admin)
    sign_out(:super_admin)
    # Inclua qualquer outro escopo (ex: :coordenador)

    flash[:notice] = "#{current_scope.to_s.capitalize} deslogado com sucesso!" if current_scope
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
