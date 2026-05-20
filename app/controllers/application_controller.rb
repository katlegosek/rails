# frozen_string_literal: true

class ApplicationController < ActionController::Base
  append_view_path Rails.root.join("app", "views", "controllers")

  before_action :set_paper_trail_whodunnit
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[first_name last_name])
  end
end
