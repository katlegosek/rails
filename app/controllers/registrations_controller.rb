# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  protected

  def after_inactive_sign_up_path_for(resource)
    new_user_session_path
  end

  def sign_up_params
    devise_parameter_sanitizer.sanitize(:sign_up).merge(role: :admin)
  end
end
