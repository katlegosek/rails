# frozen_string_literal: true

class Molecules::Modal::Component < ApplicationViewComponent
with_collection_parameter :modal

option :modal_id
option :title, optional: true, default: proc { "" }
option :class_name, optional: true, default: proc { "" }
option :auto_open, optional: true, default: proc { false }
option :scroll, optional: true, default: proc { false }

renders_one :header
renders_one :body

style do
base { "relative p-2 lg:p-4 w-full max-w-xl h-full md:h-auto" }
end
end