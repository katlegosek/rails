# frozen_string_literal: true

class Atoms::Tabs::Component < ApplicationViewComponent
  with_collection_parameter :tabs

  renders_many :tabs, "TabComponent"

  option :active_tab

  class TabComponent < ApplicationViewComponent
    attr_reader :name, :active

    def initialize(name:, &block)
      @name = name
      @active = name == @active_tab
      @content_block = block
    end

    def tab_id
      "#{@name}-tab"
    end

    def panel_id
      @name.to_s
    end

    def call; end
  end
end
