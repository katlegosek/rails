# frozen_string_literal: true

class ProcessReceiptJob < ApplicationJob
  queue_as :default

  def perform(receipt_id)
    receipt = Receipt.includes(:bill, :receipt_processing_runs).find_by(id: receipt_id)
    return unless receipt

    processing_run = receipt.receipt_processing_runs.order(created_at: :desc).first
    return unless processing_run

    receipt.processing!
    processing_run.update!(status: :processing, started_at: Time.current)

    Receipts::FakeOcrProcessor.call(receipt, processing_run: processing_run)

    receipt.ready!
    processing_run.update!(status: :completed, completed_at: Time.current)
  rescue StandardError => error
    receipt&.failed!
    processing_run&.update!(
      status: :failed,
      error_message: error.message,
      completed_at: Time.current
    )
    raise
  end
end
