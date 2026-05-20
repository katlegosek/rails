# frozen_string_literal: true

class Molecules::Table::Component < ApplicationViewComponent
  with_collection_parameter :table

  option :collection
end
