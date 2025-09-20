module ApplicationHelper

  def current_account
    current_admin || current_super_admin
  end

  # Helper to get current user regardless of type
  def current_any_user
    current_admin || current_professor || current_coordenador || current_super_admin
  end

  # Helper to get current user type as string
  def current_user_type
    return 'Administrador' if current_admin
    return 'Professor' if current_professor
    return 'Coordenador' if current_coordenador
    return 'Super Admin' if current_super_admin
    nil
  end

  # Debug helper to understand what's happening
  def debug_user_status
    {
      current_admin: current_admin.present?,
      current_super_admin: current_super_admin.present?,
      current_professor: current_professor.present?,
      current_coordenador: current_coordenador.present?,
      current_any_user_class: current_any_user&.class&.name,
      current_user_type: current_user_type
    }
  end

  # Helper to render the appropriate sidebar based on user type with explicit checks
  def render_user_sidebar
    # Explicit checks to avoid any ambiguity
    if current_admin.present? && current_super_admin.blank?
      render 'shared/admin_sidebar'
    elsif current_professor.present? && current_admin.blank? && current_super_admin.blank?
      render 'shared/professor_sidebar'
    elsif current_coordenador.present? && current_admin.blank? && current_super_admin.blank?
      render 'shared/coordenador_sidebar'
    elsif current_super_admin.present? && current_admin.blank?
      render 'shared/super_admin_sidebar'
    else
      # Debug fallback - let's see what's happening
      Rails.logger.debug "SIDEBAR DEBUG: #{debug_user_status}"
      render 'shared/super_admin_sidebar'
    end
  end

end
