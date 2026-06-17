# app/controllers/alunos/sessions_controller.rb

class Alunos::SessionsController < Devise::SessionsController
 
 # GET /resource/sign_in
 def new
  self.resource = resource_class.new
  clean_up_passwords(resource)
  yield resource if block_given?
  render 'alunos/devise/sessions/new'
 end
 
 # POST /resource/sign_in (Ação de Login)
 def create
  # 🛑 HARD RESET DE SESSÃO 🛑
  # Este passo é crucial, pois limpa qualquer rastro de SuperAdmin/Admin 
  # que pode ter ficado no servidor antes de autenticar o Aluno.
  warden.logout
    reset_session # Limpeza do hash de sessão do Rails
    
  # (Os sign_out individuais se tornam redundantes, mas podem ser mantidos para segurança extra, ou removidos)
  
  # Executa a lógica padrão de autenticação do Devise para o Aluno
  self.resource = warden.authenticate!(auth_options)
  
  if resource
   set_flash_message!(:notice, :signed_in)
   sign_in(resource_name, resource)
   yield resource if block_given?
   respond_with resource, location: after_sign_in_path_for(resource)
  else
   # Se falhar (senha errada), o Devise padrão lida com isso.
   super
  end
 end

 # DELETE /resource/sign_out (Logout)
 def destroy
   # 1. Logout Padrão
   signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
   
   # 2. Limpeza forçada no logout e reset da sessão (Garantia Máxima)
   sign_out(:super_admin)
   sign_out(:admin)
   sign_out(:professor)
   sign_out(:coordenador)
   reset_session
   
   set_flash_message! :notice, :signed_out if signed_out
   yield resource if resource
   respond_to_on_destroy
 end

  protected

  def configure_sign_in_params
    devise_parameter_sanitizer.permit(:sign_in, keys: [:matricula])
  end

  # Método auxiliar para garantir o redirecionamento correto após o logout.
  def respond_to_on_destroy
    # Usa status :see_other (303) para garantir que o navegador faça um GET limpo
    redirect_to after_sign_out_path_for(resource_name), status: :see_other
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path 
  end
end