class ConfirmationsController < Devise::ConfirmationsController
  protected

  # Override the path where user is redirected after confirmation
  def after_confirmation_path_for(resource_name, resource)
    new_user_session_path
  end
end
