# frozen_string_literal: true

class Api::Mobile::V1::BillParticipantsController < Api::Mobile::V1::BaseController
  def create
    bill = find_bill_for_current_mobile_user(params[:bill_id])
    return render_not_found("Bill not found") unless bill
    return render_bill_locked if bill_locked?(bill)

    participant = bill.bill_participants.build(participant_params)

    if participant.save
      return render_participant_response(participant, bill, status: :created)
    end

    render_validation_errors(participant)
  end

  def update
    participant = find_participant_for_current_mobile_user
    return render_not_found("Participant not found") unless participant
    return render_bill_locked if bill_locked?(participant.bill)

    if participant.update(participant_params)
      return render_participant_response(participant, participant.bill)
    end

    render_validation_errors(participant)
  end

  def destroy
    participant = find_participant_for_current_mobile_user
    return render_not_found("Participant not found") unless participant
    if participant.is_host?
      return render_validation_details(
        { participant: [ "host cannot be removed" ] },
        message: "The bill host cannot be removed."
      )
    end

    bill = participant.bill
    participant_json = Api::Mobile::V1::BillParticipantSerializer.new(participant).as_json
    BillRooms::RemoveParticipant.call(bill: bill, participant: participant)

    render json: {
      participant: participant_json,
      bill_summary: serialized_bill_summary(bill)
    }
  end

  rescue_from BillRooms::RemoveParticipant::RoomClosed do
    render_validation_details(
      { bill: [ "is already finalized" ] },
      message: "Finalized bills cannot be changed."
    )
  end

  private

  def find_bill_for_current_mobile_user(bill_id)
    current_mobile_user.bills.find_by(id: bill_id)
  end

  def find_participant_for_current_mobile_user
    BillParticipant
      .joins(:bill)
      .where(bills: { user_id: current_mobile_user.id })
      .find_by(id: params[:id])
  end

  def participant_params
    params.require(:participant).permit(
      :name,
      :initials,
      :avatar_background_color,
      :avatar_text_color,
      :seat_index,
      :is_host,
      :settled
    )
  end

  def render_participant_response(participant, bill, status: :ok)
    render json: {
      participant: Api::Mobile::V1::BillParticipantSerializer.new(participant).as_json,
      bill_summary: serialized_bill_summary(bill)
    }, status: status
  end

  def bill_locked?(bill)
    bill.session_finalized? || bill.session_closed?
  end

  def render_bill_locked
    render_validation_details(
      { bill: [ "is already finalized" ] },
      message: "Finalized bills cannot be changed."
    )
  end
end
