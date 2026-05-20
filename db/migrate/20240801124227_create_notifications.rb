# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[7.1]
  def change
    create_table :notifications do |t|
      t.string :message, null: false
      t.timestamps
    end

    create_table :notifications_users do |t|
      t.references :notification, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :read_at
      t.timestamps
    end
  end
end
