module ApplicationHelper

  def current_account
    current_professor || current_coordenador || current_admin || current_super_admin
  end

end
