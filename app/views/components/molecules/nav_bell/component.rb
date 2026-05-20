# frozen_string_literal: true

class Molecules::NavBell::Component < ApplicationViewComponent
  with_collection_parameter :nav_bell

  option :unread_count
end
