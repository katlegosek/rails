# frozen_string_literal: true

class Atoms::PageHeader::Component < ApplicationViewComponent
  with_collection_parameter :page_header

  option :title
  renders_one :actions
end
