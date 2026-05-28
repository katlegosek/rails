# frozen_string_literal: true

# Serializes a single ReceiptImage. Needs URL helpers to render the
# ActiveStorage URL for the attached image — mirrors the previous
# `receipt_image_payload` helper exactly.
class Api::Mobile::V1::ReceiptImageSerializer < Api::Mobile::V1::BaseSerializer
  include Rails.application.routes.url_helpers

  def as_json(*)
    {
      id: object.id,
      receipt_id: object.receipt_id,
      position: object.position,
      capture_type: object.capture_type,
      image_url: object.image.attached? ? url_for(object.image) : nil,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
