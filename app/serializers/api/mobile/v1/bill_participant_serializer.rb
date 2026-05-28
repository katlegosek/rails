# frozen_string_literal: true

# Serializes a single BillParticipant. Mirrors the previous
# `bill_participant_payload` helper exactly.
class Api::Mobile::V1::BillParticipantSerializer < Api::Mobile::V1::BaseSerializer
  def as_json(*)
    {
      id: object.id,
      bill_id: object.bill_id,
      name: object.name,
      initials: object.initials,
      avatar_background_color: object.avatar_background_color,
      avatar_text_color: object.avatar_text_color,
      seat_index: object.seat_index,
      is_host: object.is_host,
      settled: object.settled,
      created_at: object.created_at,
      updated_at: object.updated_at
    }
  end
end
