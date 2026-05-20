# frozen_string_literal: true

module RequestMacros
  def authenticate_administrator
    @admin = FactoryBot.create(:user, role: :admin)
    sign_in @admin
  end

  def authenticate_user
    application = FactoryBot.create(:doorkeeper_application)
    resource_owner_id = FactoryBot.create(:user).id
    @token = FactoryBot.create(:access_token, application:, resource_owner_id:)
  end

  def headers
    { Authorization: "Bearer #{@token.token}" }
  end

  def valid_user_params(**args)
    {
      user: {
        email: "user@fetza.test",
        password: 'Password1!',
        first_name: 'User',
        last_name: 'Name'
      }.merge(args)
    }
  end
end
