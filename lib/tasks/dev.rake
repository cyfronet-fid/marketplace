# frozen_string_literal: true

if Rails.env.development?
  require "faker"

  namespace :dev do
    desc "Sample data for local development environment"
    task :prime, [:services_size] => "db:setup" do |task, args|
      puts "Cleaning all services and categories"
      Service.destroy_all
      Category.destroy_all

      puts "Generating categories"
      all_categories = []
      computing = Category.create(name: "Computing")
      all_categories << computing
      all_categories << Category.create(name: "HPC", parent: computing)
      all_categories << Category.create(name: "Cloud", parent: computing)
      all_categories << Category.create(name: "Data")

      services_size = args.fetch(:services_size, 100)
      puts "Generating #{services_size} new services"
      services_size.times do
        Service.create(title: Faker::Lorem.sentence,
                       description: Faker::Lorem.paragraph,
                       categories: [all_categories.sample])
      end

      puts "Done!"
    end
  end
end
