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

puts "Generating providers form yaml"
yaml_hash["providers"].each do |_, hash|
  Provider.find_or_create_by(name: hash["name"])
end

areas = []
yaml_hash["area"].each do |_, hash|
  ResearchArea.find_or_create_by(name: hash["name"])
  puts "#{ hash["name"] } area generated"
end

puts "Generating services from yaml"
yaml_hash["services"].each do |_, hash|
  categories = Category.where(name: hash["parents"])
  providers = Provider.where(name: hash["providers"])
  area = ResearchArea.where(name: hash["area"])

  Service.find_or_initialize_by(title: hash["title"]) do |service|

    service.update!(tagline: hash["tagline"],
                    description: hash["description"],
                    provider: providers[0],
                    research_areas: area,
                    open_access: hash["open_access"],
                    connected_url: hash["connected_url"],
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
                    categories: categories)

    service.offers.create!(name: "Offer 1", description: "This is offer 1")
    service.offers.create!(name: "Offer 2", description: "This is offer 2")
  end
  puts "Generated service #{ hash["title"] }"
end

puts "Generating service relations from yaml"
puts "Remove all relations and crating new defined"
ServiceRelationship.delete_all
yaml_hash["relations"].each do |_, hash|
  source = Service.find_by(title: hash["source"])
  target = Service.find_by(title: hash["target"])
  ServiceRelationship.create!(source: source, target: target)
  if hash["both"]
    ServiceRelationship.create!(source: target, target: source)
    puts "Geneated relation from #{target.title} to #{source.title}"
  end
  puts "Geneated relation from #{source.title} to #{target.title}"
end
