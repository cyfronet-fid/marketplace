# frozen_string_literal: true

require "recommender/serialize_db"
require "pp"

namespace :recommender do
  desc "serialize database for recommender system"
  task serialize_db: :environment do
    serialized_db = Recommender::SerializeDb.new.call.to_json

    begin
      url = Mp::Application.config.recommender_host + "/database_dumps"
      puts "Sending database dump to recommender host (#{url})..."
      response = Unirest.post url,
                              { "Content-Type": "application/json", "Accept": "application/json" },
                              serialized_db

      if response.code == 204
        puts "Database dump sent successfully..."
      elsif response.code == 400
        puts "Recommender system validation error, details:"
        pp response.body["errors"]
      end
    rescue StandardError
      path = Rails.root.join("data.json")
      puts "Couldn't connect to recommender host, dumping db into #{path} instead..."
      File.open(path, "w") do |f|
        f.write(serialized_db)
      end
    end
  end
end
