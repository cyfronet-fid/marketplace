# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Initial categories and services
puts "Generating categories"
all_categories = []
computing = Category.create_with(name: "Computing").find_or_create_by(name: "Computing")
all_categories << computing
all_categories << Category.create_with(name: "HPC", parent: computing).find_or_create_by(name: "HPC")
all_categories << Category.create_with(name: "Cloud", parent: computing).find_or_create_by(name: "Cloud")
all_categories << Category.create_with(name: "Data").find_or_create_by(name: "Data")

services_size = ENV["services_size"].to_i || 0
Rake::Task["dev:prime"].invoke(services_size)
