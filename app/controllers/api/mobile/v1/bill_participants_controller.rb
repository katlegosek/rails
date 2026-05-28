# frozen_string_literal: true

class Api::Mobile::V1::BillParticipantsController < Api::Mobile::V1::BaseController
  def create
    bill = find_bill_for_current_mobile_user(params[:bill_id])
    return render_not_found("Bill not found") unless bill

    participant = bill.bill_participants.build(participant_params)

    if participant.save
      return render_participant_response(participant, bill, status: :created)
    end

    render_validation_errors(participant)
  end

  def update
    participant = find_participant_for_current_mobile_user
    return render_not_found("Participant not found") unless participant

    if participant.update(participant_params)
      return render_participant_response(participant, participant.bill)
    end

    render_validation_errors(participant)
  end

  def destroy
    participant = find_participant_for_current_mobile_user
    return render_not_found("Participant not found") unless participant

    bill = participant.bill
    participant_json = Api::Mobile::V1::BillParticipantSerializer.new(participant).as_json
    participant.destroy!

    render json: {
      participant: participant_json,
      bill_summary: serialized_bill_summary(bill)
    }
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
end
