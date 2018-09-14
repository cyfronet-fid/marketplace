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

yaml_hash["categories"].each do |category, hash|
  parent = hash["parent"] && Category.find_by(name: hash["parent"])
  if parent.blank?
    Category.create_with(name: hash["name"], description: hash["description"]).find_or_create_by(name: hash["name"])
  else
    Category.create_with(name: hash["name"], description: hash["description"], parent: parent).find_or_create_by(name: hash["name"])
  end
  puts "Generated category #{ hash["name"] }"
end

puts "Generating providers"
all_providers = []
all_providers << Provider.create_with(name: "Provider 1").find_or_create_by(name: "Provider 1")
all_providers << Provider.create_with(name: "Provider 2").find_or_create_by(name: "Provider 2")
all_providers << Provider.create_with(name: "Provider 3").find_or_create_by(name: "Provider 3")
all_providers << Provider.create_with(name: "Provider 4").find_or_create_by(name: "Provider 4")


puts "Generating services from yaml"
yaml_hash["services"].each do |service, hash|
  current = Service.create_with(title: hash["title"], tagline: hash["tagline"], description: hash["description"], provider: Provider.all.sample).find_or_create_by(title: hash["title"])
  current.categories << Category.find_by(name: hash["parent"])
  current.set_first_category_as_main!
  puts "Generated service #{ hash["title"] }"

end
