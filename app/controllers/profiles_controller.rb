# app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  layout 'dashboard'
  # Antes de qualquer ação, verifica se há algum usuário logado
  # (Você precisará adaptar este método 'authenticate_user!' ao seu setup Devise)
  before_action :authenticate_any_user!
  before_action :set_profile_user

  # GET /profile
  def show
    # A view (profile/show.html.erb) pode usar @user para exibir as informações
  end

  # GET /profile/edit
  def edit
    # A view (profile/edit.html.erb) usará @user para o formulário
  end

  # PATCH/PUT /profile
  def update
    if @user.update(profile_params)
      # Adicione a lógica para lidar com a atualização de anexos (ActiveStorage)
      # se você tiver campos como 'foto' (foto de perfil) usando ActiveStorage.
      
      redirect_to profile_path, notice: 'Seu perfil foi atualizado com sucesso. ✨'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # Método para determinar qual é o usuário logado atualmente (Professor, Admin, etc.)
  # e carregá-lo na variável @user.
  def set_profile_user
    # O Devise cria métodos 'current_NOME_DO_MODELO' para o usuário logado
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
      # Se ninguém estiver autenticado, redireciona (embora o 'authenticate_any_user!' já deva fazer isso)
      redirect_to root_path, alert: 'Você precisa estar logado para acessar seu perfil.'
    end
  end

  # Parâmetros permitidos para edição
  # Adapte isso com os campos específicos de cada modelo que você quer que sejam editáveis.
  def profile_params
    # Exemplo: Se for um Professor, permita a atualização destes campos
    if @user.is_a?(Professor)
      params.require(:professor).permit(:nome, :email, :telefone, :formacao, :foto)
    # Exemplo: Se for um Aluno, permita a atualização destes campos
    elsif @user.is_a?(Aluno)
      params.require(:aluno).permit(:nome, :email, :telefone)
    else # Admins, Coordenadores, SuperAdmins
      # Lógica para outros tipos de usuário (muitas vezes, só nome e email)
      params.require(@user.model_name.singular.to_sym).permit(:nome, :email)
    end
  end
  
  # Você precisará criar este método se ainda não tiver, 
  # para garantir que pelo menos UM tipo de usuário esteja logado.
  def authenticate_any_user!
    unless professor_signed_in? || aluno_signed_in? || admin_signed_in? || coordenador_signed_in? || super_admin_signed_in?
      redirect_to new_user_session_path, alert: "Você precisa fazer login para continuar."
    end
  end
end