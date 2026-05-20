# frozen_string_literal: true

class Atoms::Badge::Component < ApplicationViewComponent
  with_collection_parameter :badge

  option :count

  style do
    base { "w-3 h-3 inline-flex items-center justify-center p-3 ms-3 text-sm font-medium text-blue-800 bg-blue-100 rounded-full dark:bg-blue-900 dark:text-blue-300" }
  end
end
