# frozen_string_literal: true

class Api::Public::V1::ItemClaimsController < Api::Public::V1::BaseController
  def create
    update_claim(claim: true)
  end

  def destroy
    update_claim(claim: false)
  end

  private

  def update_claim(claim:)
    bill = find_public_bill_room
    return render_not_found unless bill
    return render_room_closed unless bill.session_open?

    participant = find_guest_participant(bill)
    return if performed?

    receipt_item = bill.receipt_items.find_by(id: params[:receipt_item_id])
    return render_item_not_found unless receipt_item

    bill.with_lock do
      return render_room_closed unless bill.session_open?

      receipt_item.with_lock do
        participant_ids = receipt_item.item_assignments.pluck(:bill_participant_id)
        participant_ids = if claim
          (participant_ids + [ participant.id ]).uniq
        else
          participant_ids - [ participant.id ]
        end

        ReceiptItems::ReplaceAssignments.call(
          receipt_item: receipt_item,
          participant_ids: participant_ids,
          split_method: "equal"
        )
      end
    end

    render_room(bill, current_participant: participant)
  end

  def render_room_closed
    render_api_error(
      code: :room_closed,
      message: "This bill has already been finalised.",
      status: :conflict
    )
  end

  def render_item_not_found
    render_api_error(
      code: :not_found,
      message: "Receipt item not found.",
      status: :not_found
    )
  end
end
