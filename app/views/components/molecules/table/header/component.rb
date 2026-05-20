# frozen_string_literal: true

class Molecules::Table::Header::Component < ApplicationViewComponent
  with_collection_parameter :table_header

  option :title
  option :class_names, optional: true, default: proc { "" }

  style do
    base { "px-6 py-4 text-nowrap" }
  end
end
