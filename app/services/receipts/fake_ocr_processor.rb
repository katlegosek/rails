# frozen_string_literal: true

module Receipts
  class FakeOcrProcessor
    RESTAURANT_NAME = "Observatory Small Plates"

    MENU_ITEMS = [
      { name: "Burrata & Heirloom Tomato", unit_price_cents: 9_500, category: "starter", icon_key: "plate" },
      { name: "Grilled Calamari", unit_price_cents: 11_000, category: "starter", icon_key: "fish" },
      { name: "Lamb Meatballs", unit_price_cents: 14_500, category: "main", icon_key: "meat" },
      { name: "Wild Mushroom Risotto", unit_price_cents: 12_500, category: "main", icon_key: "bowl" },
      { name: "Pan-Seared Salmon", unit_price_cents: 16_500, category: "main", icon_key: "fish" },
      { name: "Chocolate Fondant", unit_price_cents: 8_500, category: "dessert", icon_key: "dessert" },
      { name: "House Red Wine (750ml)", unit_price_cents: 22_000, category: "drinks", icon_key: "wine" },
      { name: "Espresso", unit_price_cents: 4_500, quantity: 2, category: "drinks", icon_key: "coffee" }
    ].freeze

    def self.call(receipt, processing_run:)
      new(receipt, processing_run: processing_run).call
    end

    def initialize(receipt, processing_run:)
      @receipt = receipt
      @bill = receipt.bill
      @processing_run = processing_run
    end

    def call
      extracted = build_extracted_data

      Receipt.transaction do
        clear_extracted_data
        create_receipt_items(extracted[:items])
        create_receipt_adjustments(extracted[:adjustments])
        update_processing_run(extracted)
      end

      extracted
    end

    private

    attr_reader :receipt, :bill, :processing_run

    def clear_extracted_data
      bill.receipt_items.where(receipt_id: receipt.id).destroy_all
      receipt.receipt_adjustments.destroy_all
    end

    def build_extracted_data
      items = MENU_ITEMS.map.with_index do |row, index|
        quantity = row.fetch(:quantity, 1)
        unit_price_cents = row[:unit_price_cents]
        total_cents = (unit_price_cents * quantity).round

        {
          name: row[:name],
          quantity: quantity,
          unit_price_cents: unit_price_cents,
          total_cents: total_cents,
          category: row[:category],
          icon_key: row[:icon_key],
          position: index,
          confidence: 0.92
        }
      end

      subtotal_cents = items.sum { |item| item[:total_cents] }
      service_fee_cents = (subtotal_cents * 0.10).round
      vat_cents = (subtotal_cents * 0.15).round
      total_cents = subtotal_cents + service_fee_cents + vat_cents

      adjustments = [
        { label: "Subtotal", kind: :subtotal, amount_cents: subtotal_cents, included_in_total: false, position: 0 },
        { label: "Service charge (10%)", kind: :service_fee, amount_cents: service_fee_cents, included_in_total: true, position: 1 },
        { label: "VAT (15%)", kind: :tax, amount_cents: vat_cents, included_in_total: true, position: 2 }
      ]

      {
        restaurant_name: RESTAURANT_NAME,
        subtotal_cents: subtotal_cents,
        total_cents: total_cents,
        items: items,
        adjustments: adjustments,
        raw_ocr_text: build_raw_ocr_text(items, adjustments, total_cents),
        raw_ai_response: {
          provider: "fake_ocr",
          merchant: RESTAURANT_NAME,
          restaurant_name: RESTAURANT_NAME,
          title: RESTAURANT_NAME,
          currency: "ZAR",
          subtotal_cents: subtotal_cents,
          total_cents: total_cents,
          item_count: items.size,
          debug: { simulated: true, version: 1 }
        }
      }
    end

    def build_raw_ocr_text(items, adjustments, total_cents)
      lines = [ RESTAURANT_NAME, "Observatory Restaurant", "123 Main Rd, Cape Town", "" ]
      items.each do |item|
        line_total = (item[:unit_price_cents] * item[:quantity]).round
        lines << format("%<name>-32s R%<amount>8.2f", name: item[:name], amount: line_total / 100.0)
      end
      lines << ""
      adjustments.each do |adjustment|
        lines << format("%<label>-32s R%<amount>8.2f", label: adjustment[:label], amount: adjustment[:amount_cents] / 100.0)
      end
      lines << ""
      lines << format("TOTAL%28s R%<amount>8.2f", amount: total_cents / 100.0)
      lines.join("\n")
    end

    def create_receipt_items(items)
      items.each do |attrs|
        bill.receipt_items.create!(attrs.merge(receipt: receipt))
      end
    end

    def create_receipt_adjustments(adjustments)
      adjustments.each do |attrs|
        receipt.receipt_adjustments.create!(attrs)
      end
    end

    def update_processing_run(extracted)
      processing_run.update!(
        raw_ocr_text: extracted[:raw_ocr_text],
        raw_ai_response: extracted[:raw_ai_response]
      )
    end
  end
end
