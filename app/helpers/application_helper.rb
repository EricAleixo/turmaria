module ApplicationHelper

  def current_account
    current_admin || current_super_admin
  end

end
