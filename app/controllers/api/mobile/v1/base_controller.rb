# frozen_string_literal: true

class Api::Mobile::V1::BaseController < ApplicationController
  include Api::Mobile::V1::ResponsePayloads

  respond_to :json

  skip_forgery_protection

  before_action :authenticate_mobile_user!

  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
  rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
  rescue_from ReceiptItems::ReplaceAssignments::Invalid, with: :handle_service_validation_error
  rescue_from BillAssignments::Invalid, with: :handle_service_validation_error

  private

  def current_mobile_user
    @current_mobile_user
  end

  def current_mobile_session
    @current_mobile_session
  end

  def authenticate_mobile_user!
    raw_access_token = bearer_access_token
    session = MobileSessions::TokenIssuer.find_active_by_access_token(raw_access_token)

    unless session
      return render_unauthorized
    end

    session.touch_last_used!
    @current_mobile_session = session
    @current_mobile_user = session.user
  end

  def bearer_access_token
    authorization = request.headers["Authorization"].to_s
    return if authorization.blank?

    scheme, token = authorization.split(" ", 2)
    return unless scheme.casecmp("Bearer").zero?

    token.presence
  end

  def render_unauthorized(message = "Unauthorized")
    render_api_error(code: :unauthorized, message: message, status: :unauthorized)
  end

  def render_api_error(code:, message:, status:, details: nil)
    error = {
      code: code.to_s,
      message: message
    }
    error[:details] = normalize_error_details(details) if details.present?

    render json: { error: error }, status: status
  end

  def render_not_found(message = "Resource not found")
    render_api_error(code: :not_found, message: message, status: :not_found)
  end

  def render_validation_errors(record, message: "Could not save record.")
    render_validation_details(record.errors.messages, message: message)
  end

  def render_validation_details(details, message: "Could not save record.")
    render_api_error(
      code: :validation_error,
      message: message,
      details: details,
      status: :unprocessable_content
    )
  end

  def render_bad_request(message:, details: nil)
    render_api_error(
      code: :bad_request,
      message: message,
      details: details,
      status: :bad_request
    )
  end

  def render_processing_failed(message:, details: nil)
    render_api_error(
      code: :processing_failed,
      message: message,
      details: details,
      status: :unprocessable_content
    )
  end

  def handle_record_not_found(exception)
    render_not_found(record_not_found_message(exception))
  end

  def handle_record_invalid(exception)
    render_validation_errors(exception.record)
  end

  def handle_service_validation_error(exception)
    render_validation_details(exception.errors, message: "Could not complete request.")
  end

  def handle_parameter_missing(exception)
    render_bad_request(
      message: "Required parameter is missing.",
      details: { parameter: [ exception.param.to_s ] }
    )
  end

  def handle_internal_error(exception)
    log_internal_error(exception)

    render_api_error(
      code: :server_error,
      message: server_error_message(exception),
      status: :internal_server_error
    )
  end

  def log_internal_error(exception)
    Rails.logger.error("[Api::Mobile::V1] #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace&.join("\n"))
  end

  def server_error_message(exception)
    return exception.message if expose_exception_message?

    "Something went wrong. Please try again."
  end

  def expose_exception_message?
    Rails.env.development? || Rails.env.test?
  end

  def record_not_found_message(exception)
    case exception.model
    when "Bill"
      "Bill not found"
    when "Receipt"
      "Receipt not found"
    when "ReceiptItem"
      "Receipt item not found"
    when "ReceiptAdjustment"
      "Receipt adjustment not found"
    when "BillParticipant"
      "Participant not found"
    else
      "Resource not found"
    end
  end

  def normalize_error_details(details)
    details.to_h.transform_keys(&:to_s).transform_values { |value| Array(value) }
  end
end
