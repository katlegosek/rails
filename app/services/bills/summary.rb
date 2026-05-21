# frozen_string_literal: true

module Bills
  class Summary
    def self.call(bill)
      new(bill).call
    end

    def self.bill_total_cents_for(bill)
      new(bill).bill_total_cents
    end

    def initialize(bill)
      @bill = bill
    end

    def call
      {
        bill: bill_payload,
        totals: totals_payload,
        participants: participants_payload,
        receipt_adjustments: receipt_adjustments_payload
      }
    end

    attr_reader :bill

    def bill_total_cents
      stored_receipt_total = bill.receipt&.stored_total_cents
      return stored_receipt_total if stored_receipt_total

      calculated_bill_total_cents
    end

    private

    def bill_payload
      {
        id: bill.id,
        title: bill.display_title,
        status: bill.status,
        total_cents: bill_total_cents,
        items_count: receipt_items.size,
        assigned_items_count: assigned_items_count,
        unassigned_items_count: receipt_items.size - assigned_items_count
      }
    end

    def totals_payload
      {
        bill_total_cents: bill_total_cents,
        assigned_total_cents: assigned_total_cents,
        unassigned_total_cents: bill_total_cents - assigned_total_cents,
        settled_total_cents: settled_total_cents,
        outstanding_total_cents: outstanding_total_cents
      }
    end

    def participants_payload
      bill_participants.map do |participant|
        amount_due = participant_amount_due_cents(participant)

        {
          id: participant.id,
          name: participant.name,
          initials: participant.initials,
          avatar_background_color: participant.avatar_background_color,
          avatar_text_color: participant.avatar_text_color,
          seat_index: participant.seat_index,
          is_host: participant.is_host,
          settled: participant.settled,
          amount_due_cents: amount_due,
          assigned_items_count: participant_assigned_items_count(participant)
        }
      end
    end

    def receipt_adjustments_payload
      receipt_adjustments.map do |adjustment|
        {
          id: adjustment.id,
          label: adjustment.label,
          kind: adjustment.kind,
          amount_cents: adjustment.amount_cents,
          affects_total: adjustment.affects_total,
          position: adjustment.position
        }
      end
    end

    def calculated_bill_total_cents
      items_total = receipt_items.sum(&:total_cents)
      return items_total unless bill.receipt

      affecting_adjustments_total = receipt_adjustments
        .select(&:affects_total)
        .sum(&:amount_cents)

      items_total + affecting_adjustments_total
    end

    def assigned_total_cents
      item_assignments.sum(&:amount_cents)
    end

    def settled_total_cents
      bill_participants.select(&:settled).sum { |participant| participant_amount_due_cents(participant) }
    end

    def outstanding_total_cents
      bill_participants.reject(&:settled).sum { |participant| participant_amount_due_cents(participant) }
    end

    def assigned_items_count
      receipt_items.count { |item| item.item_assignments.any? }
    end

    def participant_amount_due_cents(participant)
      participant.item_assignments.sum(&:amount_cents)
    end

    def participant_assigned_items_count(participant)
      participant.item_assignments.map(&:receipt_item_id).uniq.size
    end

    def receipt_items
      @receipt_items ||= bill.receipt_items.includes(:item_assignments).order(:position).to_a
    end

    def bill_participants
      @bill_participants ||= bill.bill_participants.includes(:item_assignments).order(:seat_index, :id).to_a
    end

    def receipt_adjustments
      @receipt_adjustments ||= bill.receipt&.receipt_adjustments&.order(:position)&.to_a || []
    end

    def item_assignments
      @item_assignments ||= receipt_items.flat_map(&:item_assignments)
    end
  end
end
