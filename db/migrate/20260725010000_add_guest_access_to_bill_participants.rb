# frozen_string_literal: true

class AddGuestAccessToBillParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :bill_participants, :guest_token_digest, :string
    add_column :bill_participants, :joined_at, :datetime

    add_index :bill_participants, :guest_token_digest, unique: true
  end
end
