# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  before(:each) do
    FactoryBot.create(:notification, users: [ FactoryBot.create(:user) ])
  end

  context "validations" do
    subject { FactoryBot.build(:notification, users: [ FactoryBot.create(:user) ]) }

    it { should validate_presence_of(:message) }

    it { should have_many(:notifications_users).dependent(:destroy) }
    it { should have_many(:users) }

    it "creates" do
      expect(FactoryBot.create(:notification, users: [ FactoryBot.create(:user) ])).to be_valid
    end
  end

  context "scopes" do
    describe "by_search" do
      it "should return a record if given a valid term" do
        expect(Notification.by_search(Notification.first.message).any?).to be_truthy
      end

      it "should not return a record if given a invalid term" do
        expect(Notification.by_search("random").any?).to be_falsey
      end

      it "should return everything if blank" do
        expect(Notification.by_search.count).to eq(Notification.count)
      end
    end
  end

  context "functions" do
    describe "read! and read?" do
      it "should mark the notification as read for the current user" do
        notification = Notification.first
        user = User.first

        notification.read!(user)
        expect(notification.read?(user)).to be_truthy
      end

      it "should do nothing because this user is not linked" do
        notification = Notification.first
        new_user = FactoryBot.create(:user)

        notification.read!(new_user)
        expect(notification.read?(new_user)).to eq(nil)
      end
    end

    describe "broadcast_notification" do
      it "broadcasts to update the notifications count" do
        user = FactoryBot.create(:user)
        notification = FactoryBot.build(:notification, users: [ user ])

        expect do
          notification.save!
        end.to have_broadcasted_to("broadcast_to_user_#{user.id}").exactly(3).times
      end

      it "should append since there are more than 1 unread notifications" do
        user = FactoryBot.create(:user)
        FactoryBot.create(:notification, users: [ user ])
        notification = FactoryBot.build(:notification, users: [ user ])

        expect do
          notification.save!
        end.to have_broadcasted_to("broadcast_to_user_#{user.id}").exactly(3).times
      end
    end
  end
end
