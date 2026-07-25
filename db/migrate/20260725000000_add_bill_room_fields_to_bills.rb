# frozen_string_literal: true

class AddBillRoomFieldsToBills < ActiveRecord::Migration[8.1]
  def change
    add_column :bills, :session_status, :string, null: false, default: "draft"
    add_column :bills, :share_token, :string
    add_column :bills, :confirmed_at, :datetime
    add_column :bills, :finalized_at, :datetime

    add_index :bills, :session_status
    add_index :bills, :share_token, unique: true
  end
end
