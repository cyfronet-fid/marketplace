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
all_categories = []

yaml_hash["categories"].each do |category, hash|
  parent = hash["parent"] && Category.find_by(name: hash["parent"])
  all_categories << Category.create!(name: hash["name"], description: hash["description"], parent: parent)
end

puts "Generating services from yaml"
all_services = []
yaml_hash["services"].each do |service, hash|
  current = Service.create(title: hash["title"], tagline: hash["tagline"], description: hash["description"])
  all_services << current
  current.categories << Category.find_by(name: hash["parent"])
  current.set_first_category_as_main!

end

services_size = ENV["services_size"].to_i || 0
Rake::Task["dev:prime"].invoke(services_size)
