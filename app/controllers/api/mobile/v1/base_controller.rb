# frozen_string_literal: true

class Api::Mobile::V1::BaseController < ApplicationController
  respond_to :json

  skip_forgery_protection
end
