# frozen_string_literal: true

module Api::Mobile::V1::ResponsePayloads::ParticipantPayloads
  extend ActiveSupport::Concern

  private

  def bill_participant_payload(participant)
    {
      id: participant.id,
      bill_id: participant.bill_id,
      name: participant.name,
      initials: participant.initials,
      avatar_background_color: participant.avatar_background_color,
      avatar_text_color: participant.avatar_text_color,
      seat_index: participant.seat_index,
      is_host: participant.is_host,
      settled: participant.settled,
      created_at: participant.created_at,
      updated_at: participant.updated_at
    }
  end
end
