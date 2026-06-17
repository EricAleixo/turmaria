class Devise::UnifiedSessionsController < Devise::SessionsController
  layout "application"
  helper_method :resource, :resource_name, :devise_mapping

  def new
    @resource = OpenStruct.new(email: "")
  end


  def create
    email = params[resource_name][:email]
    password = params[resource_name][:password]

    @resource = OpenStruct.new(email: email)

    registro = EmailCadastro.find_by(email: email)

    unless registro
      flash.now[:alert] = "Email não encontrado"
      render :new
      return
    end

    # 🚫 BLOQUEIO TOTAL: aluno NÃO loga por email
    if registro.user_type == "Aluno"
      flash.now[:alert] = "Não é possível logar com email. Use sua matrícula."
      render :new
      return
    end

    user = registro.user_type.constantize.find_by(id: registro.user_id)

    unless user
      flash.now[:alert] = "Dados inconsistentes. Usuário não encontrado."
      render :new
      return
    end

    unless user.valid_password?(password)
      flash.now[:alert] = "Senha inválida"
      render :new
      return
    end

    # ✅ LOGIN PERMITIDO (Professor / Admin / etc)
    sign_in(user)
    UserMailer.login_alert(user).deliver_later
    flash[:notice] = "#{registro.user_type} logado com sucesso!"
    redirect_to after_sign_in_path_for(user)
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
