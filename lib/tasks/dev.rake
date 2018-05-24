# frozen_string_literal: true

if Rails.env.development?
  require "faker"

  namespace :dev do
    desc "Sample data for local development environment"
    task :prime, [:services_size] => "db:setup" do |task, args|
      puts "Cleaning all services"
      Service.destroy_all

      services_size = args.fetch(:services_size, 100)
      puts "Generating #{services_size} new services"
      services_size.times do
        Service.create(title: Faker::Lorem.sentence,
                       description: Faker::Lorem.paragraph)
      end

      puts "Done!"
    end
  end
end
