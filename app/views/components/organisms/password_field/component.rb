# frozen_string_literal: true

class Organisms::PasswordField::Component < Molecules::Input::Component
  with_collection_parameter :password_field

  option :field_type, optional: true, default: proc { "password_field" }
  option :autocomplete, optional: true, default: proc { "current-password" }
end
