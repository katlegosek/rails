# frozen_string_literal: true

module BillRooms
  class RemoveGuest
    def self.call(bill:, participant:)
      new(bill: bill, participant: participant).call
    end

    def initialize(bill:, participant:)
      @bill = bill
      @participant = participant
    end

    def call
      validate_guest!
      BillRooms::RemoveParticipant.call(bill: bill, participant: participant)
    end

    private

    attr_reader :bill, :participant

    def validate_guest!
      return if participant.guest_token_digest.present?

      raise ArgumentError, "Participant is not a guest in this bill room"
    end
  end
end
