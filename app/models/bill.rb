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
end
