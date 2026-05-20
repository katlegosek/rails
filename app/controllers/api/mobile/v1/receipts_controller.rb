# frozen_string_literal: true

class Api::Mobile::V1::ReceiptsController < Api::Mobile::V1::BaseController
  def show
    receipt = find_receipt_for_current_user
    return render_not_found("Receipt not found") unless receipt

    render json: receipt_show_json(receipt)
  end

  private

  def find_receipt_for_current_user
    Receipt
      .joins(:bill)
      .includes(
        :receipt_adjustments,
        :receipt_processing_runs,
        bill: :receipt_items
      )
      .where(bills: { user_id: current_user.id })
      .find_by(id: params[:id])
  end

  def receipt_show_json(receipt)
    payload = {
      receipt: receipt_payload(receipt),
      processing_run: latest_processing_run_payload(receipt)
    }

    if receipt.ready? || receipt.confirmed?
      payload[:receipt_items] = receipt.bill.receipt_items
        .where(receipt_id: receipt.id)
        .order(:position)
        .map { |item| receipt_item_payload(item) }
      payload[:receipt_adjustments] = receipt.receipt_adjustments.order(:position).map { |adjustment| receipt_adjustment_payload(adjustment) }
    end

    payload
  end

  def latest_processing_run_payload(receipt)
    run = receipt.receipt_processing_runs.order(created_at: :desc).first
    return nil unless run

    processing_run_payload(run)
  end
end
