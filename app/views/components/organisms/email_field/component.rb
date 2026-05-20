# frozen_string_literal: true

class Organisms::EmailField::Component < Molecules::Input::Component
  with_collection_parameter :email_field

  option :field_type, optional: true, default: proc { "email_field" }
  option :autocomplete, optional: true, default: proc { "email" }
end
