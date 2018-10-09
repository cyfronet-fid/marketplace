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
                    categories: [Category.find_by(name: hash["parent"])])

  end
  puts "Generated service #{ hash["title"] }"
end
