# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :system do
  before(:each) do
    authenticate_admin
  end

  describe "Lock and unlock" do
    before(:each) do
      @user = FactoryBot.create(:user)
    end

    it "should lock then unlock the user's account", js: true do
      visit users_path
      find("#view-user-#{@user.id}").click
      click_on "Lock"
      sleep 0.1
      @user.reload
      expect(@user.locked_at).not_to be_nil
      click_on "Unlock"
      sleep 0.1
      @user.reload
      expect(@user.locked_at).to be_nil
      expect(page).to have_text("Lock")
    end
  end

  describe "Editing a user" do
    before(:each) do
      @user = FactoryBot.create(:user)
    end

    it "should edit the user's first name", js: true do
      visit users_path
      find("#edit-user-#{@user.id}").click
      fill_in "First name", with: "Testing"
      click_on "Update"
      expect(page).to have_text("Testing")
    end

    it "should fail because the email is already used", js: true do
      visit users_path
      find("#edit-user-#{@user.id}").click
      fill_in "Email", with: @admin.email
      click_on "Update"
      expect(page).to have_text("Has already been taken")
    end
  end
end
