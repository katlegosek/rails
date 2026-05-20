# frozen_string_literal: true

class BaseController < ApplicationController
  layout "app"

  before_action :authenticate_user!
end
