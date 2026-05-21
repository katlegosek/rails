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
  validates :subtotal_cents, :total_cents, :tax_cents, :service_fee_cents, :tip_cents, :discount_cents,
    numericality: { only_integer: true }
  validates :currency, presence: true

  def stored_total_cents
    total_cents.positive? ? total_cents : nil
  end

  def calculated_total_cents
    items_total = receipt_items.sum(:total_cents)
    adjustments_total = receipt_adjustments.where(affects_total: true).sum(:amount_cents)
    items_total + adjustments_total
  end
end
