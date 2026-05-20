# frozen_string_literal: true

namespace :db do
  desc "Drop, create, migrate, and seed the database"
  task reload: :environment do
    if Rails.env.development? || Rails.env.staging?
      Rake::Task["db:drop"].invoke
      Rake::Task["db:create"].invoke
      Rake::Task["db:migrate"].invoke
      Rake::Task["db:seed"].invoke
    else
      puts "This task can only be run in the development environment."
    end
  end
end
