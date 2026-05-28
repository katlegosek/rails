# frozen_string_literal: true

class Api::Mobile::V1::BaseController < ApplicationController
  UNAUTHORIZED_MESSAGE = "You need to sign in to continue."

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

  def current_doorkeeper_token
    @current_doorkeeper_token
  end

  # Resolves the bearer token and the user behind it, rejecting requests with
  # a missing/invalid/expired/revoked token, a missing user, or a soft-deleted
  # user. All failure paths render the same JSON shape so the mobile app can
  # treat any 401 here uniformly.
  def authenticate_mobile_user!
    @current_doorkeeper_token = MobileAuth::TokenIssuer.find_accessible_access_token(
      bearer_access_token
    )
    return render_unauthorized unless @current_doorkeeper_token

    @current_mobile_user = User.find_by(id: @current_doorkeeper_token.resource_owner_id)
    return render_unauthorized unless @current_mobile_user
    return render_unauthorized if mobile_user_deleted?(@current_mobile_user)

    nil
  end

  def mobile_user_deleted?(user)
    user.respond_to?(:deleted_at) && user.deleted_at.present?
  end

  def bearer_access_token
    authorization = request.headers["Authorization"].to_s
    return if authorization.blank?

    scheme, token = authorization.split(" ", 2)
    return unless scheme && scheme.casecmp("Bearer").zero?

    token.to_s.strip.presence
  end

  # Tolerant of missing/already-revoked tokens — used by /auth/logout, which
  # should always return success.
  def revoke_bearer_access_token_if_present
    raw = bearer_access_token
    return if raw.blank?

    token = Doorkeeper::AccessToken.by_token(raw)
    token&.revoke unless token.nil? || token.revoked?
  end

  def render_unauthorized(message = UNAUTHORIZED_MESSAGE)
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

  # Re-loads the bill scoped to the current user and eager-loads the
  # associations Bills::Summary needs. Used by every controller that
  # renders the `bill_summary:` payload so summary computation always
  # uses an authorized record (and never accidentally includes another
  # user's data via the passed-in instance).
  def bill_for_summary(bill)
    current_mobile_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: :receipt_adjustments,
        receipt_items: :item_assignments,
        bill_participants: :item_assignments
      )
      .find(bill.id)
  end

  def serialized_bill_summary(bill)
    Api::Mobile::V1::BillSummarySerializer.new(bill_for_summary(bill)).as_json
  end
end
