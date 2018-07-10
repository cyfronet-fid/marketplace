# frozen_string_literal: true

if Rails.env.development?
  require "faker"

  namespace :dev do
    desc "Sample data for local development environment"
    task :prime, [:services_size] => "db:setup" do |task, args|
      services_size = args.fetch(:services_size, 100).to_i
      puts "Generating #{services_size} new services"
      services_size.times do
        Service.create(title: Faker::Lorem.sentence,
                       description: Faker::Lorem.paragraph,
                       terms_of_use: Faker::Lorem.paragraph,
                       categories: [Category.all.sample])
      end
      puts "Done!"
    end
  end
end
