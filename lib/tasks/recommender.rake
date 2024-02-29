# frozen_string_literal: true

require "recommender_lib/serialize_db"

namespace :recommender do
  desc "serialize database for recommender_lib system"
  task serialize_db: :environment do
    puts "Generating database dump..."
    serialized_db = RecommenderLib::SerializeDb.new.call.to_json
    puts "Database dump generated successfully!"

    begin
      url = Mp::Application.config.recommender_host + "/database_dumps"
      puts "Sending database dump to recommender host (#{url})..."
      response = Faraday.post url, serialized_db, { "Content-Type": "application/json", Accept: "application/json" }

      case response.status
      when 204
        puts "Database dump sent successfully!"
      when 400
        puts "Recommender system validation error, details:"
        pp JSON.parse(response.body)["errors"]
      end
    rescue StandardError
      path = Rails.root.join("data.json")
      puts "Couldn't connect to recommender host, dumping db into #{path} instead..."
      File.write(path, serialized_db)
      puts "Database dump saved to file successfully!"
    end
  end

  task update: :environment do
    puts "Generating database dump..."
    serialized_db = RecommenderLib::SerializeDb.new.call.to_json
    puts "Database dump generated successfully!"

    begin
      url = Mp::Application.config.recommender_host + "/update"
      puts "Sending database dump to recommender host (#{url})..."
      response = Faraday.post url, serialized_db, { "Content-Type": "application/json", Accept: "application/json" }

      case response.status
      when 204
        puts "Database dump sent successfully!"
      when 400
        puts "Recommender system validation error, details:"
        pp JSON.parse(response.body)["errors"]
      end
    rescue StandardError
      path = Rails.root.join("data.json")
      puts "Couldn't connect to recommender host, dumping db into #{path} instead..."
      File.write(path, serialized_db)
      puts "Database dump saved to file successfully!"
    end
  end

  task serialize_db_to_file: :environment do
    puts "Generating database dump..."
    serialized_db = RecommenderLib::SerializeDb.new.call.to_json
    puts "Database dump generated successfully!"

    path = Rails.root.join("data.json")

    puts "Saving database dump (to #{path})..."
    File.write(path, serialized_db)
    puts "Database dump saved successfully!"
  end
end
