# frozen_string_literal: true

# Serializes a single ReceiptImage. Needs URL helpers to render the
# ActiveStorage URL for the attached image — mirrors the previous
# `receipt_image_payload` helper exactly.
#
# TODO(production-image-urls): `url_for(blob)` returns a path-only URL
# unless ActiveStorage::Current.url_options (or Rails.application.routes
# .default_url_options) is set for the current request/environment.
# Today only the receipt-image request specs configure that explicitly
# (see spec/requests/api/mobile/v1/receipt_images_spec.rb). Before the
# mobile app starts relying on these URLs in staging/production, add a
# `config.action_controller.default_url_options` + matching ActiveStorage
# host config per environment (dev = localhost:3000, staging/production
# = the public host) so this serializer always emits absolute URLs that
# the mobile client can hit. See docs/DEV_ONLY_TODOS.md for tracking.
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
