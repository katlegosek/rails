# frozen_string_literal: true

class CreateMobileSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :mobile_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :access_token_digest, null: false
      t.string :refresh_token_digest, null: false
      t.datetime :access_token_expires_at, null: false
      t.datetime :refresh_token_expires_at, null: false
      t.datetime :revoked_at
      t.datetime :last_used_at

      t.timestamps
    end

    add_index :mobile_sessions, :access_token_digest, unique: true
    add_index :mobile_sessions, :refresh_token_digest, unique: true
  end
end
