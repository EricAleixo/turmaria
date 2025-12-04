# app/controllers/profiles_controller.rb
# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  layout 'dashboard'
  
  before_action :authenticate_any_user!
  before_action :set_profile_user

  # GET /profile
  def show
    if current_super_admin
      render "profiles/super_admin_profile"

    elsif current_admin
      @escola = @user.escolas[0]
      render "profiles/admin_profile"

    elsif current_professor
      render "profiles/professor_profile"

    elsif current_aluno
      render "profiles/aluno_profile"

    else
      redirect_to root_path, alert: "Acesso não permitido"
    end
  end


  # GET /profile/edit
  def edit
  end

  # PATCH/PUT /profile
  def update
    # 1. Obtém os parâmetros permitidos (pode ser um hash vazio se nada for enviado)
    permitted_params = profile_params
    
    # Se permitted_params vier vazio, pulamos as etapas de limpeza para evitar erros.
    if permitted_params.present?
      
      # 2. Lógica de Devise: Remove a senha se os campos vierem vazios
      # Usamos .delete (que não falha se a chave não existir) no hash de parâmetros.
      if permitted_params[:password].blank? && permitted_params[:password_confirmation].blank?
        permitted_params = permitted_params.except(:password, :password_confirmation)
      end
      
      # 3. Lógica de ActiveStorage: Remove a foto se a checkbox foi marcada
      if permitted_params[:remove_foto].to_i == 1 && @user.respond_to?(:foto) && @user.foto.attached?
        @user.foto.purge_later
        # Remove o parâmetro, pois a remoção já foi tratada
        permitted_params = permitted_params.except(:remove_foto)
      end
    end
    
    # Tenta atualizar com os parâmetros limpos (pode ser um hash vazio)
    if @user.update(permitted_params)
      # Se a atualização de perfil (incluindo senha, se fornecida) foi bem-sucedida
      redirect_to profile_path, notice: 'Seu perfil foi atualizado com sucesso.'
    else
      # Se a validação do Devise ou ActiveRecord falhar
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Método para determinar qual é o usuário logado atualmente (Professor, Admin, etc.)
  def set_profile_user
    if professor_signed_in?
      @user = current_professor
    elsif aluno_signed_in?
      @user = current_aluno
    elsif admin_signed_in?
      @user = current_admin
    elsif coordenador_signed_in?
      @user = current_coordenador
    elsif super_admin_signed_in?
      @user = current_super_admin
    else
      redirect_to root_path, alert: 'Você precisa estar logado para acessar seu perfil.'
    end
  end

  # Parâmetros permitidos para edição (Versão Híbrida e Robusta)
  def profile_params
    base_params = [:nome, :email, :telefone, :foto, :password, :password_confirmation, :remove_foto]

    # Determinamos o nome do modelo (ex: :professor)
    model_name_sym = @user.model_name.singular.to_sym
    
    # 1. Tenta buscar os parâmetros aninhados (o que o HTML está enviando)
    # 2. Se falhar, usa o hash params completo (para capturar campos não aninhados)
    source = params.fetch(model_name_sym, params)
    
    # 3. Permite os campos base
    if @user.is_a?(Professor)
      return source.permit(*base_params, :formacao)
    elsif @user.is_a?(Aluno)
      return source.permit(*base_params, :data_nascimento)
    else # Admins, Coordenadores, SuperAdmins (parâmetros mais limitados)
      return source.permit(:nome, :email, :password, :password_confirmation)
    end
  end
  
  # Garante que pelo menos UM tipo de usuário esteja logado.
  def authenticate_any_user!
    unless professor_signed_in? || aluno_signed_in? || admin_signed_in? || coordenador_signed_in? || super_admin_signed_in?
      redirect_to new_user_session_path, alert: "Você precisa fazer login para continuar."
    end
  end
end