# frozen_string_literal: true

class Api::Mobile::V1::BillParticipantsController < Api::Mobile::V1::BaseController
  def create
    bill = find_bill_for_current_user(params[:bill_id])
    return render_not_found unless bill

    participant = bill.bill_participants.build(participant_params)

    if participant.save
      return render_participant_response(participant, bill, status: :created)
    end

    render_validation_errors(participant)
  end

  def update
    participant = find_participant_for_current_user
    return render_not_found("Participant not found") unless participant

    if participant.update(participant_params)
      return render_participant_response(participant, participant.bill)
    end

    render_validation_errors(participant)
  end

  def destroy
    participant = find_participant_for_current_user
    return render_not_found("Participant not found") unless participant

    bill = participant.bill
    participant_json = participant_payload(participant)
    participant.destroy!

    render json: {
      participant: participant_json,
      bill_summary: bill_summary_for(bill)
    }
  end

  private

  def find_bill_for_current_user(bill_id)
    current_user.bills.find_by(id: bill_id)
  end

  def find_participant_for_current_user
    BillParticipant
      .joins(:bill)
      .where(bills: { user_id: current_user.id })
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
      participant: participant_payload(participant),
      bill_summary: bill_summary_for(bill)
    }, status: status
  end

  def participant_payload(participant)
    {
      id: participant.id,
      bill_id: participant.bill_id,
      name: participant.name,
      initials: participant.initials,
      avatar_background_color: participant.avatar_background_color,
      avatar_text_color: participant.avatar_text_color,
      seat_index: participant.seat_index,
      is_host: participant.is_host,
      settled: participant.settled,
      created_at: participant.created_at,
      updated_at: participant.updated_at
    }
  end

  def bill_summary_for(bill)
    Bills::Summary.call(bill_for_summary(bill))
  end

  def bill_for_summary(bill)
    current_user.bills
      .includes(
        :receipt_items,
        :bill_participants,
        receipt: :receipt_adjustments,
        receipt_items: :item_assignments,
        bill_participants: :item_assignments
      )
      .find(bill.id)
  end
end
