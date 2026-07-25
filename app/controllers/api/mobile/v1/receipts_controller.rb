# frozen_string_literal: true

class Api::Mobile::V1::ReceiptsController < Api::Mobile::V1::BaseController
  def show
    receipt = find_receipt_for_current_mobile_user
    return render_not_found("Receipt not found") unless receipt

    render json: receipt_show_json(receipt)
  end

  # Locks in the reviewed receipt so the bill can move on to assignment.
  # Only receipts whose OCR has finished (`ready`) can be confirmed; calling
  # it again on an already-confirmed receipt is a no-op success (idempotent).
  def confirm
    receipt = find_receipt_for_current_mobile_user
    return render_not_found("Receipt not found") unless receipt

    unless receipt.ready? || receipt.confirmed?
      return render_validation_details(
        { status: [ "must be ready before it can be confirmed" ] },
        message: "This receipt is not ready to confirm yet."
      )
    end

    receipt.confirmed! unless receipt.confirmed?

    render json: receipt_show_json(receipt)
  end

  private

  def find_receipt_for_current_mobile_user
    Receipt
      .joins(:bill)
      .includes(
        :receipt_adjustments,
        :receipt_processing_runs,
        bill: :receipt_items
      )
      .where(bills: { user_id: current_mobile_user.id })
      .find_by(id: params[:id])
  end

  def receipt_show_json(receipt)
    payload = {
      receipt: Api::Mobile::V1::ReceiptSerializer.new(receipt).as_json,
      processing_run: latest_processing_run_json(receipt)
    }

    if receipt.ready? || receipt.confirmed?
      payload[:receipt_items] = Api::Mobile::V1::ReceiptItemSerializer.collection(
        receipt.bill.receipt_items.where(receipt_id: receipt.id).order(:position)
      )
      payload[:receipt_adjustments] = Api::Mobile::V1::ReceiptAdjustmentSerializer.collection(
        receipt.receipt_adjustments.order(:position)
      )
    end

    payload
  end

  def latest_processing_run_json(receipt)
    run = receipt.receipt_processing_runs.order(created_at: :desc).first
    return nil unless run

    Api::Mobile::V1::ReceiptProcessingRunSerializer.new(run).as_json
  end
end
