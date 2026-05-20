# frozen_string_literal: true

class AddBillTitleAndReceiptTotals < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :title, :string

    change_table :receipts, bulk: true do |t|
      t.string :merchant_name
      t.date :receipt_date
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0
      t.string :currency, null: false, default: "ZAR"
      t.integer :tax_cents, null: false, default: 0
      t.integer :service_fee_cents, null: false, default: 0
      t.integer :tip_cents, null: false, default: 0
      t.integer :discount_cents, null: false, default: 0
    end
  end
end
