# frozen_string_literal: true

module Api::Mobile::V1::ResponsePayloads::ReceiptPayloads
  extend ActiveSupport::Concern

  include Rails.application.routes.url_helpers

  private

  def receipt_payload(receipt)
    {
      id: receipt.id,
      bill_id: receipt.bill_id,
      status: receipt.status,
      merchant_name: receipt.merchant_name,
      receipt_date: receipt.receipt_date,
      subtotal_cents: receipt.subtotal_cents,
      total_cents: receipt.total_cents,
      currency: receipt.currency,
      tax_cents: receipt.tax_cents,
      service_fee_cents: receipt.service_fee_cents,
      tip_cents: receipt.tip_cents,
      discount_cents: receipt.discount_cents,
      created_at: receipt.created_at,
      updated_at: receipt.updated_at
    }
  end

  def receipt_status_payload(receipt)
    {
      id: receipt.id,
      status: receipt.status
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
      affects_total: adjustment.affects_total,
      position: adjustment.position,
      created_at: adjustment.created_at,
      updated_at: adjustment.updated_at
    }
  end

  def processing_run_payload(processing_run)
    {
      id: processing_run.id,
      receipt_id: processing_run.receipt_id,
      provider: processing_run.provider,
      status: processing_run.status,
      error_message: processing_run.error_message,
      started_at: processing_run.started_at,
      completed_at: processing_run.completed_at,
      created_at: processing_run.created_at,
      updated_at: processing_run.updated_at
    }
  end

  def receipt_image_payload(receipt_image)
    {
      id: receipt_image.id,
      receipt_id: receipt_image.receipt_id,
      position: receipt_image.position,
      capture_type: receipt_image.capture_type,
      image_url: receipt_image.image.attached? ? url_for(receipt_image.image) : nil,
      created_at: receipt_image.created_at,
      updated_at: receipt_image.updated_at
    }
  end
end
