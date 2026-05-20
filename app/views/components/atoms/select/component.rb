# frozen_string_literal: true

class Atoms::Select::Component < BaseFormComponent
  with_collection_parameter :select

  option :options, default: proc { [] }
  option :html_options, optional: true, default: proc { {} }
  option :default_select, optional: true, default: proc { "" }
end
