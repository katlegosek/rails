# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :system do
  describe "login" do
    before do
      @user = FactoryBot.create(:user, role: :admin)
      visit root_path
    end

    context "Login" do
      it "should succeed", js: true do
        within "form" do
          fill_in "Email", with: @user.email
          fill_in "Password", with: "Password1!"
          check "Remember me"
          click_on "Log in"
        end

        expect(page).to have_current_path(root_path)
      end

      it "should fail", js: true do
        within "form" do
          fill_in "Email", with: @user.email
          fill_in "Password", with: "RandomPassword1!"
          check "Remember me"
          click_on "Log in"
        end

        expect(page).to have_text "Invalid Email or password"
      end
    end

    context "Logout" do
      it "should succeed", js: true do
        within "form" do
          fill_in "Email", with: @user.email
          fill_in "Password", with: "Password1!"
          check "Remember me"
          click_on "Log in"
        end

        expect(page).to have_current_path(root_path)
        click_on "Open user menu"
        click_on "Sign Out"
        expect(page).to have_current_path(new_user_session_path)
      end
    end

    context "Register" do
      it "should succeed", js: true do
        click_on "Sign up"

        @user = FactoryBot.build(:user, role: :admin)

        within "form" do
          fill_in "Email", with: @user.email
          fill_in "First name", with: @user.first_name
          fill_in "Last name", with: @user.last_name
          fill_in "Password", with: "Password1!"
          fill_in "Confirm new password", with: "Password1!"
          click_on "Sign up"
        end

        sleep 0.1

        mail = ActionMailer::Base.deliveries.last
        token = mail.body.decoded.match(/confirmation_token=([^"]+)/)[1]

        visit user_confirmation_path(confirmation_token: token)
        expect(page).to have_text "Your email address has been successfully confirmed."

        fill_in "Email", with: @user.email
        fill_in "Password", with: "Password1!"
        click_on "Log in"

        expect(page).to have_current_path(root_path)
      end
    end

    context "Forgot Password" do
      it "should succeed", js: true do
        click_on "Forgot your password?"

        within "form" do
          fill_in "Email", with: @user.email
          click_on "Send me reset password instructions"
        end

        sleep 0.1

        mail = ActionMailer::Base.deliveries.last
        token = mail.body.decoded.match(/reset_password_token=([^"]+)/)[1]

        visit edit_user_password_path(reset_password_token: token)
        within "form" do
          fill_in "New password", with: "Password2!"
          fill_in "Confirm new password", with: "Password2!"
          click_on "Change my password"
        end

        expect(page).to have_text "Dashboard"
      end
    end

    context "Didn't receive confirmation instructions" do
      it "should succeed", js: true do
        @user.update(confirmed_at: nil)
        click_on "Didn't receive confirmation instructions?"

        within "form" do
          fill_in "user_email", with: @user.email
          click_on "Resend confirmation instructions"
        end

        sleep 0.1

        mail = ActionMailer::Base.deliveries.last
        token = mail.body.decoded.match(/confirmation_token=([^"]+)/)[1]

        visit user_confirmation_path(confirmation_token: token)
        expect(page).to have_text "Your email address has been successfully confirmed."

        fill_in "Email", with: @user.email
        fill_in "Password", with: "Password1!"
        click_on "Log in"

        expect(page).to have_current_path(root_path)
      end
    end

    context "Didn't receive unlock instructions" do
      it "should succeed", js: true do
        @user.lock_access!
        click_on "Didn't receive unlock instructions?"

        within "form" do
          fill_in "user_email", with: @user.email
          click_on "Resend unlock instructions"
        end

        sleep 0.2

        mail = ActionMailer::Base.deliveries.last
        token = mail.body.decoded.match(/unlock_token=([^"]+)/)[1]

        visit user_unlock_path(unlock_token: token)
        expect(page).to have_text "Your account has been unlocked successfully. Please sign in to continue."

        fill_in "Email", with: @user.email
        fill_in "Password", with: "Password1!"
        click_on "Log in"

        expect(page).to have_current_path(root_path)
      end
    end
  end
end
