# frozen_string_literal: true

require "rails_helper"
require Rails.root.join "spec/concerns/system/searchable.rb"
require Rails.root.join "spec/concerns/system/paginatable.rb"
require Rails.root.join "spec/concerns/system/navigable.rb"

RSpec.describe "Notifications", type: :system do
  before(:each) do
    authenticate_admin
    @notification = FactoryBot.create(:notification)
  end

  it_behaves_like "searchable" do
    let(:path) { notifications_path }
    let(:search_content) { @notification.message }
  end

  it_behaves_like "paginatable" do
    let(:path) { notifications_path }
    let(:generate_enough_records) do
      10.times do
        FactoryBot.create(:notification)
      end
    end
  end

  it_behaves_like "navigable" do
    let(:path) { notifications_path }
    let(:action) do
      find("#view-notification-0").click
    end
    let(:destination_path) { notification_path(@notification.id) }
  end

  describe "creating a notification", js: true do
    before(:each) do
      visit notifications_path
      click_on "Create"
    end

    it "should create" do
      fill_in "Message", with: "New Message"
      select User.first.full_name, from: "notification_user_ids"
      click_on "Create"
    end
  end
end
