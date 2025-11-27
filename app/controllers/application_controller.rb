class ApplicationController < ActionController::Base
  include Pundit::Authorization
  
  helper_method :current_any_user, :current_user_type, :user_signed_in?, :current_user

  # Tratamento de erros do Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Retorna o usuário logado (qualquer tipo)
  def current_any_user
    current_aluno || current_professor || current_coordenador || current_admin || current_super_admin
  end



  def authenticated_user_type
  # A ordem é: Quem tem o helper Devise presente?
  return Aluno if current_aluno.present?
  return Professor if current_professor.present?
  return Coordenador if current_coordenador.present?
  return Admin if current_admin.present?
  return SuperAdmin if current_super_admin.present?
  nil # Ninguém logado
end

# Torna os métodos disponíveis para todas as Views
helper_method :current_any_user, :authenticated_user_type



  # Alias para compatibilidade com Pundit
  def current_user
    current_any_user
  end

  # Método auxiliar para Pundit quando não há usuário logado
  def pundit_user
    current_user
  end

  # Retorna o tipo de usuário logado como string
  def current_user_type
    case current_any_user
    when Admin then "Administrador"
    when Professor then "Professor"
    when Coordenador then "Coordenador"
    when SuperAdmin then "Super Admin"
    else nil
    end
  end

  # Verifica se algum usuário está logado
  def user_signed_in?
    current_any_user.present?
  end

  protected

  # Override Devise's after_confirmation_path_for to use our custom login path
  def after_confirmation_path_for(resource_name, resource)
    new_user_session_path
  end

  # Override Devise's after_sign_in_path_for to redirect based on user type and school association
  def after_sign_in_path_for(resource)
    case resource
    when Admin
      if resource.escolas.present?
        # Admin já tem escola, vai para o show da escola
        escola_path(resource.escola)
      else
        # Admin não tem escola, vai para a tela de boas-vindas
        welcome_escola_path
      end
    when SuperAdmin
      # Super Admin vai para o dashboard de super admin
      dashboard_path
    else
      # Outros tipos de usuário vão para o dashboard
      dashboard_path
    end
  end

  private

  def redirect_unless_school_exists
    # Assumindo que você tem um helper 'current_admin' para o usuário logado
    # e que o modelo Admin tem uma associação `has_one :escola`.
    
    # 1. Se o administrador não estiver logado, pare a execução (o Devise ou outro sistema cuida disso).
    # O `authenticate_admin!` geralmente já lida com isso se estiver usando Devise.
    return unless defined?(current_admin) && current_admin 

    # 2. Se o admin não tiver uma escola, redireciona para a tela de cadastro.
    # O `escola.nil?` ou `escola.blank?` verifica se a associação existe.
    if current_admin.escola.nil?
      # Evita loops de redirecionamento se já estiver na página de welcome
      unless controller_name == "welcome" && action_name == "index"
        redirect_to welcome_path, notice: "Por favor, cadastre sua escola para continuar."
      end
    end
  end

  def user_not_authorized
    flash[:alert] = "Você não tem permissão para realizar essa ação."
    redirect_to root_path
  end
end
