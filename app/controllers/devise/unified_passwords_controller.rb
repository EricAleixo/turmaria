class Devise::UnifiedPasswordsController < ApplicationController
  helper_method :resource, :resource_name, :devise_mapping

  def new
    @resource = OpenStruct.new(email: "")
  end

  def create
    email = params[:professor][:email] 
    registro = EmailCadastro.find_by(email: email)

    if registro
      user = registro.user_type.constantize.find(registro.user_id)

      if user
        user.send_reset_password_instructions
        flash[:notice] = "Instruções enviadas para #{email}!"
        redirect_to user_session_path
      else
        flash.now[:alert] = "Usuário não encontrado"
        @resource = OpenStruct.new(email: email)
        render :new
      end
    else
      flash.now[:alert] = "Email não encontrado"
      @resource = OpenStruct.new(email: email)
      render :new
    end
  end
  def edit
    @resource = find_user_by_token
    unless @resource
      redirect_to new_edit_user_password_path, alert: "Token inválido"
    end
  end

  def update
    @resource = find_user_by_token
    unless @resource
      redirect_to new_password_path, alert: "Token inválido" and return
    end

    if @resource.reset_password(params[:user][:password], params[:user][:password_confirmation])
      flash[:notice] = "Senha atualizada com sucesso!"
      redirect_to login_path
    else
      flash.now[:alert] = @resource.errors.full_messages.join(", ")
      render :edit
    end
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


  def find_user_by_token
    token = params[:reset_password_token]
    registro = EmailCadastro.find_by(reset_password_token: token) 
    return unless registro
    registro.user_type_constantize_find(registro.user_id)
  end
end
