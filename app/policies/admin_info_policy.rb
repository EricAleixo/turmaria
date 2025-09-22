class AdminInfoPolicy < ApplicationPolicy
  # Policy para controlar quem pode ver informações de administradores
  
  def show?
    user.is_a?(SuperAdmin)
  end

  # Alias para diferentes contextos
  def view_admin_info?
    show?
  end

  def see_admin_details?
    show?
  end
end
