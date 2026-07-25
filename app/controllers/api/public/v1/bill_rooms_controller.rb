# frozen_string_literal: true

class Api::Public::V1::BillRoomsController < Api::Public::V1::BaseController
  def show
    bill = find_public_bill_room
    return render_not_found unless bill

    render_room(
      bill,
      current_participant: find_guest_participant(bill, required: false)
    )
  end

  def join
    bill = find_public_bill_room
    return render_not_found unless bill
    return render_room_closed unless bill.session_open?

    if bearer_access_token
      existing_participant = find_guest_participant(bill, required: false)
      return render_invalid_guest_token unless existing_participant

      return render_room(bill, current_participant: existing_participant)
    end

    participant = nil
    guest_token = nil

    bill.with_lock do
      return render_room_closed unless bill.session_open?

      participant = bill.bill_participants.create!(
        name: join_params[:name].to_s.strip,
        initials: initials_for(join_params[:name]),
        seat_index: bill.bill_participants.maximum(:seat_index).to_i + 1,
        joined_at: Time.current
      )
      guest_token = participant.issue_guest_token!
    end

    render_room(
      bill,
      current_participant: participant,
      guest_token: guest_token,
      status: :created
    )
  end

  private

  def join_params
    params.require(:guest).permit(:name)
  end

  def initials_for(name)
    name.to_s.split.filter_map(&:first).first(2).join.upcase
  end

  def render_invalid_guest_token
    render_api_error(
      code: :unauthorized,
      message: "Your guest session is no longer valid.",
      status: :unauthorized
    )
  end
end
