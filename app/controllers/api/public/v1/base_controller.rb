# frozen_string_literal: true

class Api::Public::V1::BaseController < ApplicationController
  respond_to :json

  skip_forgery_protection

  rescue_from StandardError, with: :handle_internal_error
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
  rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid

  private

  def find_public_bill_room
    Bill
      .where(session_status: %i[open finalized])
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: :receipt_adjustments,
        receipt_items: :item_assignments
      )
      .find_by(share_token: params[:share_token])
  end

  def bearer_access_token
    scheme, token = request.headers["Authorization"].to_s.split(" ", 2)
    return unless scheme&.casecmp("Bearer")&.zero?

    token.to_s.strip.presence
  end

  def find_guest_participant(bill, required: true)
    raw_token = bearer_access_token
    participant = if raw_token
      bill.bill_participants.find_by(
        guest_token_digest: BillParticipant.digest_guest_token(raw_token)
      )
    end

    return participant if participant
    return unless required

    render_api_error(
      code: :unauthorized,
      message: "Join this bill room before claiming items.",
      status: :unauthorized
    )
    nil
  end

  def render_room(bill, current_participant: nil, status: :ok, guest_token: nil)
    payload = Api::Public::V1::BillRoomSerializer.new(
      bill.reload,
      current_participant: current_participant
    ).as_json
    payload[:guest_token] = guest_token if guest_token

    render json: payload, status: status
  end

  def render_api_error(code:, message:, status:, details: nil)
    error = { code: code.to_s, message: message }
    error[:details] = details.to_h.transform_keys(&:to_s) if details.present?
    render json: { error: error }, status: status
  end

  def render_not_found
    render_api_error(
      code: :not_found,
      message: "Bill room not found.",
      status: :not_found
    )
  end

  def handle_record_invalid(exception)
    render_api_error(
      code: :validation_error,
      message: "Could not join the bill room.",
      details: exception.record.errors.messages,
      status: :unprocessable_content
    )
  end

  def handle_parameter_missing(exception)
    render_api_error(
      code: :bad_request,
      message: "Required parameter is missing.",
      details: { parameter: [ exception.param.to_s ] },
      status: :bad_request
    )
  end

  def handle_internal_error(exception)
    Rails.logger.error("[Api::Public::V1] #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace&.join("\n"))

    render_api_error(
      code: :server_error,
      message: Rails.env.production? ? "Something went wrong. Please try again." : exception.message,
      status: :internal_server_error
    )
  end
end
