# frozen_string_literal: true

# Serializes a single ReceiptProcessingRun. Mirrors the previous
# `processing_run_payload` helper exactly.
class Api::Mobile::V1::ReceiptProcessingRunSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      receipt_id: object.receipt_id,
      provider: object.provider,
      status: object.status,
      error_message: object.error_message,
      started_at: object.started_at,
      completed_at: object.completed_at,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
