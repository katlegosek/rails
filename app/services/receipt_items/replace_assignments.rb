# frozen_string_literal: true

module ReceiptItems
  class ReplaceAssignments
    class Invalid < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super(errors.to_json)
      end
    end

    def self.call(receipt_item:, participant_ids:, split_method:)
      new(receipt_item: receipt_item, participant_ids: participant_ids, split_method: split_method).call
    end

    def initialize(receipt_item:, participant_ids:, split_method:)
      @receipt_item = receipt_item
      @participant_ids = Array(participant_ids).map(&:to_i).uniq
      @split_method = split_method.to_s
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        receipt_item.item_assignments.destroy_all
        create_equal_assignments! if participant_ids.any?
      end

      receipt_item.reload
    end

    private

    attr_reader :receipt_item, :participant_ids, :split_method

    def validate!
      errors = {}

      unless split_method == "equal"
        errors[:split_method] = [ "must be equal" ]
      end

      if participant_ids.any?
        bill_participant_count = receipt_item.bill.bill_participants.where(id: participant_ids).count
        if bill_participant_count != participant_ids.size
          errors[:participant_ids] = [ "must belong to the same bill as the receipt item" ]
        end
      end

      raise Invalid, errors if errors.any?
    end

    def create_equal_assignments!
      participants = receipt_item.bill.bill_participants.where(id: participant_ids).order(:id).to_a
      ordered_participants = participant_ids.filter_map { |id| participants.find { |participant| participant.id == id } }
      amounts = equal_amounts_cents(receipt_item.total_cents, ordered_participants.size)

      ordered_participants.zip(amounts).each do |participant, amount_cents|
        receipt_item.item_assignments.create!(
          bill_participant: participant,
          amount_cents: amount_cents,
          split_method: :equal
        )
      end
    end

    def equal_amounts_cents(total_cents, count)
      return [] if count.zero?

      base, remainder = total_cents.divmod(count)
      Array.new(count) { base }.tap do |amounts|
        remainder.times { |index| amounts[index] += 1 }
      end
    end
  end
end
