# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Initial categories and services
require "yaml"
puts "Generating categories from yaml"
yaml_hash = YAML.load_file("db/data.yml")

yaml_hash["categories"].each do |_, hash|
  Category.find_or_initialize_by(name: hash["name"]) do |category|
    category.update!(description: hash["description"],
                     parent: Category.find_by(name: hash["parent"]))
  end
  puts "Generated category #{ hash["name"] }"
end

puts "Generating providers"
providers = (1..4).map { |i| Provider.find_or_create_by(name: "Provider #{i}") }


puts "Generating services from yaml"
yaml_hash["services"].each do |_, hash|
  Service.find_or_initialize_by(title: hash["title"]) do |service|
    service.update!(tagline: hash["tagline"],
                    description: hash["description"],
                    provider: providers.sample,
                    webpage_url: hash["webpage_url"],
                    manual_url: hash["manual_url"],
                    helpdesk_url: hash["helpdesk_url"],
                    tutorial_url: hash["tutorial_url"],
                    terms_of_use_url: hash["terms_of_use_url"],
                    corporate_sla_url: hash["corporate_sla_url"],
                    access_policies_url: hash["access_policies_url"],
                    places: hash["places"],
                    languages: hash["languages"],
                    dedicated_for: hash["dedicated_for"],
                    restrictions: hash["restrictions"],
                    phase: hash["phase"],
                    categories: [Category.find_by(name: hash["parent"])])

    service.offers.create!(title: "Offer 1", description: "This is offer 1")
    service.offers.create!(title: "Offer 2", description: "This is offer 2")
  end
  puts "Generated service #{ hash["title"] }"
end
