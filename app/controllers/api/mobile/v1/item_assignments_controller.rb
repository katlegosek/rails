# frozen_string_literal: true

class Api::Mobile::V1::ItemAssignmentsController < Api::Mobile::V1::BaseController
  def update
    receipt_item = find_receipt_item_for_current_user
    return render_not_found("Receipt item not found") unless receipt_item

    ReceiptItems::ReplaceAssignments.call(
      receipt_item: receipt_item,
      participant_ids: assignment_params[:participant_ids],
      split_method: assignment_params[:split_method]
    )

    render_receipt_item_response(receipt_item)
  rescue ReceiptItems::ReplaceAssignments::Invalid => e
    render json: { errors: e.errors }, status: :unprocessable_content
  end

  def destroy
    receipt_item = find_receipt_item_for_current_user
    return render_not_found("Receipt item not found") unless receipt_item

    ReceiptItems::ReplaceAssignments.call(
      receipt_item: receipt_item,
      participant_ids: [],
      split_method: "equal"
    )

    render_receipt_item_response(receipt_item)
  rescue ReceiptItems::ReplaceAssignments::Invalid => e
    render json: { errors: e.errors }, status: :unprocessable_content
  end

  private

  def find_receipt_item_for_current_user
    ReceiptItem
      .joins(:bill)
      .where(bills: { user_id: current_user.id })
      .find_by(id: params[:receipt_item_id])
  end

  def assignment_params
    params.permit(:split_method, participant_ids: [])
  end

  def render_receipt_item_response(receipt_item)
    bill = receipt_item.bill

    render json: {
      receipt_item: receipt_item_payload(receipt_item),
      bill_summary: bill_summary_for(bill)
    }
  end

  def receipt_item_payload(item)
    {
      id: item.id,
      bill_id: item.bill_id,
      receipt_id: item.receipt_id,
      name: item.name,
      quantity: item.quantity.to_f,
      unit_price_cents: item.unit_price_cents,
      total_cents: item.total_cents,
      category: item.category,
      icon_key: item.icon_key,
      position: item.position,
      confidence: item.confidence&.to_f,
      created_at: item.created_at,
      updated_at: item.updated_at
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
