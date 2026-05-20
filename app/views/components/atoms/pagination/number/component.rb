# frozen_string_literal: true

class Atoms::Pagination::Number::Component < ApplicationViewComponent
  with_collection_parameter :pagination_item

  option :page_number, optional: true
  option :active, optional: true, default: false
  option :more, optional: true, default: false

  style do
    base { "flex items-center justify-center px-3 h-8 w-8 border border-gray-300 dark:border-gray-700" }
    variants {
      active {
        active { "text-primary bg-primary/10 hover:bg-primary/15 hover:text-primary/80 dark:bg-gray-700 dark:text-white" }
        inactive { "leading-tight text-gray-500 bg-white hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white" }
      }
    }
  end

  def before_render
    @tag = :a
    @tag = :span if more
    @name = ""
    @href = url_for(request.params.merge(page: page_number)) unless more
  end

  attr_reader :tag, :name, :href
end
