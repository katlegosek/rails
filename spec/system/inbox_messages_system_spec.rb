# frozen_string_literal: true

require "rails_helper"
require Rails.root.join "spec/concerns/system/searchable.rb"
require Rails.root.join "spec/concerns/system/paginatable.rb"
require Rails.root.join "spec/concerns/system/navigable.rb"

RSpec.describe "Inbox Messages", type: :system do
  before(:each) do
    authenticate_admin
    @admin.notifications << FactoryBot.create(:notification)
    @notification = @admin.notifications.first
  end

  it_behaves_like "searchable" do
    let(:path) { inbox_messages_path }
    let(:search_content) { @notification.message }
  end

  it_behaves_like "paginatable" do
    let(:path) { inbox_messages_path }
    let(:generate_enough_records) do
      10.times do
        @admin.notifications << FactoryBot.create(:notification)
      end
    end
  end

  it_behaves_like "navigable" do
    let(:path) { inbox_messages_path }
    let(:action) do
      find("#view-inbox-messages-#{@notification.id}").click
    end
    let(:destination_path) { inbox_message_path(@notification.id) }
  end

  describe "Reading a notification" do
    it "Should should be marked as read", js: true do
      FactoryBot.create(:notification)
      visit inbox_messages_path

      find("#view-inbox-messages-#{@notification.id}").click

      visit inbox_messages_path
      find("#view-inbox-messages-#{@notification.id}").click

      sleep 0.1
      @admin.reload
      expect(@admin.notifications.last.notifications_users.last.read_at).not_to be_nil
    end
  end
end
