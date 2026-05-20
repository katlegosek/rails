# frozen_string_literal: true

class Molecules::Table::Cell::Component < ApplicationViewComponent
  with_collection_parameter :table_cell

  option :body, optional: true
  option :class_names, optional: true, default: proc { "" }
  option :tooltip, optional: true, default: proc { "" }

  style do
    base { "px-6 py-3" }
  end
end
