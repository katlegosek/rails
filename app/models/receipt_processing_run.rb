# frozen_string_literal: true

class ReceiptProcessingRun < ApplicationRecord
  belongs_to :receipt

  enum :status, {
    pending: "pending",
    processing: "processing",
    completed: "completed",
    failed: "failed"
  }, default: :pending

  validates :status, presence: true
end
