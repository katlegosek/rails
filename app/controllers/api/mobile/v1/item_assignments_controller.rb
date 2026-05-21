# frozen_string_literal: true

class Api::Mobile::V1::ItemAssignmentsController < Api::Mobile::V1::BaseController
  def update
    receipt_item = find_receipt_item_for_current_mobile_user
    return render_not_found("Receipt item not found") unless receipt_item

    ReceiptItems::ReplaceAssignments.call(
      receipt_item: receipt_item,
      participant_ids: assignment_params[:participant_ids],
      split_method: assignment_params[:split_method]
    )

    render_receipt_item_response(receipt_item)
  end

  def destroy
    receipt_item = find_receipt_item_for_current_mobile_user
    return render_not_found("Receipt item not found") unless receipt_item

    ReceiptItems::ReplaceAssignments.call(
      receipt_item: receipt_item,
      participant_ids: [],
      split_method: "equal"
    )

    render_receipt_item_response(receipt_item)
  end

  private

  def find_receipt_item_for_current_mobile_user
    ReceiptItem
      .joins(:bill)
      .where(bills: { user_id: current_mobile_user.id })
      .find_by(id: params[:receipt_item_id])
  end

  def assignment_params
    params.permit(:split_method, participant_ids: [])
  end

  def render_receipt_item_response(receipt_item)
    render json: {
      receipt_item: receipt_item_payload(receipt_item),
      bill_summary: bill_summary_payload(receipt_item.bill)
    }
  end
end
