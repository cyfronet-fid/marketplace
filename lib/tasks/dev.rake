# frozen_string_literal: true

if Rails.env.development?
  require "faker"

  namespace :dev do
    desc "Sample data for local development environment"
    task :prime, [:services_size] => "db:setup" do |task, args|
      users = User.all + [nil]
      services_size = args.fetch(:services_size, 100).to_i
      areas = ResearchArea.all
      platforms = Platform.all
      puts "Generating #{services_size} new services"
      services_size.times do
        Service.create(title: Faker::Lorem.sentence,
                       description: Faker::Lorem.paragraph,
                       terms_of_use: Faker::Lorem.paragraph,
                       tagline: Faker::Lorem.sentence,
                       categories: [Category.all.sample],
                       owner: users.sample,
                       rating: Random.rand(5.0),
                       connected_url: Faker::Internet.url,
                       providers: Provider.all.sample(2),
                       places: Faker::Address.country,
                       languages: Faker::Nation.language,
                       dedicated_for: [Faker::Lorem.sentence],
                       terms_of_use_url: Faker::Internet.url,
                       access_policies_url: Faker::Internet.url,
                       corporate_sla_url: Faker::Internet.url,
                       webpage_url: Faker::Internet.url,
                       manual_url: Faker::Internet.url,
                       helpdesk_url: Faker::Internet.url,
                       tutorial_url: Faker::Internet.url,
                       restrictions: Faker::Lorem.sentence,
                       phase: Faker::Lorem.sentence,
                       research_areas: [areas.sample],
                       platforms: [platforms.sample])

      end

      puts "Done!"

    end
  end
end
