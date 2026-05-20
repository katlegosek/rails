# frozen_string_literal: true

class Receipt < ApplicationRecord
  belongs_to :bill

  has_many :receipt_images, dependent: :destroy
  has_many :receipt_processing_runs, dependent: :destroy
  has_many :receipt_items, dependent: :nullify
  has_many :receipt_adjustments, dependent: :destroy

  enum :status, {
    draft: "draft",
    processing: "processing",
    ready: "ready",
    failed: "failed",
    confirmed: "confirmed"
  }, default: :draft

  validates :status, presence: true
end
