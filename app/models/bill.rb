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

  enum :session_status, {
    draft: "draft",
    open: "open",
    finalized: "finalized",
    closed: "closed"
  }, prefix: :session, default: :draft

  validates :status, :session_status, presence: true
  validates :share_token, uniqueness: true, allow_nil: true

  def display_title
    title.presence ||
      receipt&.merchant_name.presence ||
      ocr_title_fallback.presence ||
      "Untitled bill"
  end

  def receipt_name
    receipt&.merchant_name.presence || ocr_merchant_fallback || display_title
  end

  def receipt_date
    receipt&.receipt_date || receipt&.created_at&.to_date
  end
  def latest_receipt_processing_run
    return unless receipt

    receipt.receipt_processing_runs.order(Arel.sql("completed_at DESC NULLS LAST"), created_at: :desc).first
  end

  def ensure_share_token!
    return share_token if share_token.present?

    loop do
      token = SecureRandom.urlsafe_base64(24)
      next if self.class.exists?(share_token: token)

      update!(share_token: token)
      return token
    end
  end

  private

  def ocr_title_fallback
    ocr_response[:title].presence || ocr_response[:merchant].presence
  end

  def ocr_merchant_fallback
    ocr_response[:merchant].presence
  end

  def ocr_response
    ai_response = latest_receipt_processing_run&.raw_ai_response
    return {} if ai_response.blank?

    ai_response.respond_to?(:with_indifferent_access) ? ai_response.with_indifferent_access : ai_response
  end
end
