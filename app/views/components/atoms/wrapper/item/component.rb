# frozen_string_literal: true

class Atoms::Wrapper::Item::Component < ApplicationViewComponent
  with_collection_parameter :wrapper_item

  option :title
  option :body, optional: true
  option :class_names, optional: true, default: proc { "" }

  style do
    base { "dark:text-white" }
  end
end
