class ApplicationViewComponent < ViewComponentContrib::Base
  extend Dry::Initializer

  include Dry::Effects.Reader(:current_user, default: nil)
  include ViewComponentContrib::StyleVariants

  style_config.postprocess_with do |classes|
    TailwindMerge::Merger.new.merge(classes)
  end
end
