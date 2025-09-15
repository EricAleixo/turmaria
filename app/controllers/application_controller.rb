class ApplicationController < ActionController::Base
  helper_method :current_any_user, :current_user_type, :user_signed_in?

  # Retorna o usuário logado (qualquer tipo)
  def current_any_user
    @current_any_user ||= current_admin || current_professor || current_coordenador || current_super_admin
  end

  # Retorna o tipo de usuário logado como string
  def current_user_type
    case current_any_user
    when Admin then "Admin"
    when Professor then "Professor"
    when Coordenador then "Coordenador"
    when Aluno then "Aluno"
    else nil
    end
  end

  # Verifica se algum usuário está logado
  def user_signed_in?
    current_any_user.present?
  end
end


