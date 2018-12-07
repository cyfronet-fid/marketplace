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

yaml_hash["area"].each do |_, hash|
  # !!! Warning: parent need to be defined before child in yaml !!!
  parent = ResearchArea.find_by(name: hash["parent"])
  ResearchArea.find_or_initialize_by(name: hash["name"]) do |ra|
    ra.update!(parent: parent)
  end
  puts "#{ hash["name"] } area generated"
end


yaml_hash["platforms"].each do |_, hash|
  Platform.find_or_create_by(name: hash["name"])
  puts "#{ hash["name"] } platforms generated"
end

yaml_hash["target_groups"].each do |_, hash|
  TargetGroup.find_or_create_by(name: hash["name"])
  puts "Created #{ hash["name"] } target group"
end

puts "Generating services from yaml"
yaml_hash["services"].each do |_, hash|
  categories = Category.where(name: hash["parents"])
  providers = Provider.where(name: hash["providers"])
  area = ResearchArea.where(name: hash["area"])
  platforms = Platform.where(name: hash["platforms"])
  target_groups = TargetGroup.where(name: hash["target_groups"])

  Service.find_or_initialize_by(title: hash["title"]) do |service|

    service_type = if hash["offers"].blank?
      hash["open_access"] ? "catalog" : "normal"
    else
      hash["open_access"] ? "open_access" : "normal"
    end

    service.update!(tagline: hash["tagline"],
                    description: hash["description"],
                    research_areas: area,
                    providers: providers,
                    service_type: service_type,
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
                    target_groups: target_groups,
                    restrictions: hash["restrictions"],
                    phase: hash["phase"],
                    categories: categories,
                    tag_list: hash["tags"],
                    platforms: platforms,
                    status: :published)

    service.logo.attached? && service.logo.purge_later
    hash["logo"] && service.logo.attach(io: File.open("db/logos/#{hash["logo"]}"), filename: hash["logo"])

    hash["offers"] && hash["offers"].each do |_, h|
      service.offers.create!(name: h["name"], description: h["description"], parameters: h["parameters"])
    end
  end
  puts "Generated service #{ hash["title"] }"
end

puts "Generating service relations from yaml"
puts "Remove all relations and crating new defined"
ServiceRelationship.delete_all
yaml_hash["relations"] && yaml_hash["relations"].each do |_, hash|
  source = Service.find_by(title: hash["source"])
  target = Service.find_by(title: hash["target"])
  ServiceRelationship.create!(source: source, target: target)
  if hash["both"]
    ServiceRelationship.create!(source: target, target: source)
    puts "Geneated relation from #{target.title} to #{source.title}"
  end
  puts "Geneated relation from #{source.title} to #{target.title}"
end
