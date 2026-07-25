# frozen_string_literal: true

class Api::Public::V1::GuestSessionsController < Api::Public::V1::BaseController
  def update
    bill = find_public_bill_room
    return render_not_found unless bill
    return render_room_closed unless bill.session_open?

    participant = find_guest_participant(bill)
    return if performed?

    bill.with_lock do
      return render_room_closed unless bill.session_open?

      participant.update!(
        name: guest_params[:name].to_s.strip,
        initials: initials_for(guest_params[:name])
      )
    end

    render_room(bill, current_participant: participant)
  end

  def destroy
    bill = find_public_bill_room
    return render_not_found unless bill
    return render_room_closed unless bill.session_open?

    participant = find_guest_participant(bill)
    return if performed?

    BillRooms::RemoveGuest.call(bill: bill, participant: participant)
    render_room(bill)
  end

  private

  def guest_params
    params.require(:guest).permit(:name)
  end

  def initials_for(name)
    name.to_s.split.filter_map(&:first).first(2).join.upcase
  end
end
