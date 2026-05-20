# frozen_string_literal: true

class Bill < ApplicationRecord
  belongs_to :user

  has_one :receipt, dependent: :destroy
  has_many :receipt_items, dependent: :destroy
  has_many :receipt_adjustments, through: :receipt
  has_many :bill_participants, dependent: :destroy
  has_many :item_assignments, through: :receipt_items

  enum :status, {
    draft: "draft",
    active: "active",
    completed: "completed",
    archived: "archived"
  }, default: :draft

  validates :status, presence: true

  def display_title
    ai_response = latest_receipt_processing_run&.raw_ai_response
    return "Untitled bill" if ai_response.blank?

    response = ai_response.respond_to?(:with_indifferent_access) ? ai_response.with_indifferent_access : ai_response
    response[:title].presence || response[:merchant].presence || "Untitled bill"
  end

  def receipt_name
    ai_response = latest_receipt_processing_run&.raw_ai_response
    return nil if ai_response.blank?

    response = ai_response.respond_to?(:with_indifferent_access) ? ai_response.with_indifferent_access : ai_response
    response[:merchant].presence || display_title
  end

  def receipt_date
    receipt&.created_at
  end

  def total_cents
    items_total = receipt_items.sum(:total_cents)
    return items_total unless receipt

    adjustments_total = receipt.receipt_adjustments.where(included_in_total: true).sum(:amount_cents)
    items_total + adjustments_total
  end

  def latest_receipt_processing_run
    return unless receipt

    receipt.receipt_processing_runs.order(Arel.sql("completed_at DESC NULLS LAST"), created_at: :desc).first
  end
end
