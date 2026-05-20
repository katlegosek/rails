# frozen_string_literal: true

class Atoms::Pagination::Action::Component < ApplicationViewComponent
  with_collection_parameter :pagination_item

  option :resources
  option :prev, optional: true, default: proc { false }

  style do
    base { "flex items-center justify-center px-3 h-8 leading-tight text-gray-500 bg-white border border-gray-300 hover:bg-gray-100 hover:text-gray-700 dark:bg-gray-800 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-white" }
    variants {
      active {
        prev { "ms-0 rounded-s-lg" }
        not_prev { "rounded-e-lg" }
      }
    }
  end

  def before_render
    @tag = :a
    @tag = :span if (resources.first_page? && prev) || (resources.last_page? && !prev)
    @name = "Next"
    @name = "Prev" if prev
    @href = url_for(request.params.merge(page: prev ? resources.prev_page : resources.next_page))
  end

  attr_reader :tag, :name, :href
end
