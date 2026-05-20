# frozen_string_literal: true

class Molecules::DrawerItem::Component < ApplicationViewComponent
  with_collection_parameter :drawer_item

  option :name
  option :icon
  option :badge, optional: true, default: proc { "" }
  option :badge_id, optional: true, default: proc { "" }
  option :href, optional: true, default: proc { "#" }
  option :children, optional: true, default: proc { [] }

  style do
    base { "flex items-center p-2 text-base font-medium text-white rounded-lg dark:text-white hover:bg-black/20 dark:hover:bg-gray-700 group" }
  end
end
