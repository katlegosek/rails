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

  def receipt_payload(receipt)
    {
      id: receipt.id,
      bill_id: receipt.bill_id,
      status: receipt.status,
      created_at: receipt.created_at,
      updated_at: receipt.updated_at
    }
  end

  def latest_processing_run_payload(receipt)
    run = receipt.receipt_processing_runs.order(created_at: :desc).first
    return nil unless run

    {
      id: run.id,
      receipt_id: run.receipt_id,
      provider: run.provider,
      status: run.status,
      error_message: run.error_message,
      started_at: run.started_at,
      completed_at: run.completed_at,
      created_at: run.created_at,
      updated_at: run.updated_at
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

  def receipt_adjustment_payload(adjustment)
    {
      id: adjustment.id,
      receipt_id: adjustment.receipt_id,
      label: adjustment.label,
      kind: adjustment.kind,
      amount_cents: adjustment.amount_cents,
      included_in_total: adjustment.included_in_total,
      position: adjustment.position,
      created_at: adjustment.created_at,
      updated_at: adjustment.updated_at
    }
  end
end
