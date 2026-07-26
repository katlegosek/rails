# frozen_string_literal: true

module BillRooms
  class RemoveParticipant
    def self.call(bill:, participant:)
      new(bill: bill, participant: participant).call
    end

    def initialize(bill:, participant:)
      @bill = bill
      @participant = participant
    end

    def call
      validate_participant!

      ActiveRecord::Base.transaction do
        bill.lock!
        raise BillRooms::RoomClosed if bill.session_finalized? || bill.session_closed?

        claimed_items.find_each do |receipt_item|
          receipt_item.with_lock do
            remaining_participant_ids = receipt_item.item_assignments
              .where.not(bill_participant_id: participant.id)
              .pluck(:bill_participant_id)

            ReceiptItems::ReplaceAssignments.call(
              receipt_item: receipt_item,
              participant_ids: remaining_participant_ids,
              split_method: "equal"
            )
          end
        end

        participant.destroy!
      end

      bill.reload
    end

    private

    attr_reader :bill, :participant

    def claimed_items
      bill.receipt_items
        .joins(:item_assignments)
        .where(item_assignments: { bill_participant_id: participant.id })
        .order(:id)
        .distinct
    end

    def validate_participant!
      return if participant.bill_id == bill.id && !participant.is_host?

      raise ArgumentError, "The host cannot be removed from a bill room"
    end
  end
end
