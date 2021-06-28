# frozen_string_literal: true

require "oms_export/serialize"

namespace :oms_export do
  desc "Data export for initial OMS seeding"

  task serialize_to_json: :environment do
    puts "Generating data for initial OMS seeding..."
    json = OMSDataExport::Serialize.new.call.to_json
    puts "JSON file generated successfully!"

    path = Rails.root.join("data_for_initial_oms_seeding.json")

    puts "Saving JSON file (to #{path})..."
    File.open(path, "w") do |f|
      f.write(json)
    end
    puts "JSON file saved successfully!"
  end
end
