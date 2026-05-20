# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::Mobile::V1::UsersController, type: :request do
  context 'logged in' do
    before(:each) do
      authenticate_user
    end

    describe 'GET /user' do
      it 'returns the user' do
        get(api_mobile_v1_user_url, headers:)

        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /user' do
      it 'updates the user' do
        patch api_mobile_v1_user_url, headers:, params: valid_user_params(first_name: 'New User')

        expect(response).to have_http_status(:ok)
      end

      it 'fails to updates the user' do
        email = 'other+user@codehesion.co.za'
        FactoryBot.create(:user, email:)

        patch api_mobile_v1_user_url, headers:, params: valid_user_params(email:)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  context 'not logged in' do
    describe 'GET /user' do
      it 'fails to return the user' do
        get api_mobile_v1_user_url

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'PATCH /user' do
      it 'fails to update the user' do
        patch api_mobile_v1_user_url, params: valid_user_params

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'POST /user' do
      it 'creates a user' do
        post api_mobile_v1_user_url, params: valid_user_params

        expect(response).to have_http_status(:created)
      end

      it 'failed to create the user' do
        post api_mobile_v1_user_url, params: valid_user_params(email: nil)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe 'POST /forgot_password' do
    before do
      @user = FactoryBot.create(:user)
    end

    it 'should return a token with a valid email' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['token'].present?).to be_truthy
    end

    it 'should fail with no email' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: nil } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'should return a fake token with unknown email' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: 'really-random' } }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['token'].present?).to be_truthy
    end
  end

  describe 'POST /verify_otp' do
    before do
      @user = FactoryBot.create(:user)
    end

    it 'should return a new token with a valid email and reset password token' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }
      otp_code = User.first.otp_code
      token = JSON.parse(response.body)['token']
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code:, token: } }

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['token'].present?).to be_truthy
    end

    it 'should failed with a valid invalid otp' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }
      otp_code = 123_456
      token = JSON.parse(response.body)['token']
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code:, token: } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'should fail with an invalid otp or token' do
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code: nil, token: nil } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'should fail with an expired token' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }
      otp_code = 123_456
      reset_password_token = JSON.parse(response.body)['reset_password_token']
      User.first.update(reset_password_sent_at: Time.zone.now - 1.week)
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code:, reset_password_token: } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe 'POST /reset_password' do
    before do
      @user = FactoryBot.create(:user)
    end

    it 'should change the password with a valid token' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }
      otp_code = User.first.otp_code
      token = JSON.parse(response.body)['token']
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code:, token: } }
      token = JSON.parse(response.body)['token']
      password = 'Password1!'
      post reset_password_api_mobile_v1_user_url, params: { user: { token:, password:, password_confirmation: password } }

      expect(response).to have_http_status(:ok)
    end

    it 'should failed with a non matching password' do
      post forgot_password_api_mobile_v1_user_url, params: { user: { email: User.first.email } }
      otp_code = User.first.otp_code
      reset_password_token = JSON.parse(response.body)['reset_password_token']
      post verify_otp_api_mobile_v1_user_url, params: { user: { otp_code:, reset_password_token: } }
      reset_password_token = JSON.parse(response.body)['reset_password_token']
      password = 'Password1!'
      password_confirmation = 'Password2!'
      post reset_password_api_mobile_v1_user_url, params: { user: { reset_password_token:, password:, password_confirmation: } }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it 'should fail with an invalid token' do
      post reset_password_api_mobile_v1_user_url, params: { user: { reset_password_token: 'random' } }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
