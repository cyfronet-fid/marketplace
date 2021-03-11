# frozen_string_literal: true

require "recommender/serialize_db"

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
      puts "Response code: #{response.code}"
      puts "Response body: #{response.body.blank? ? "empty" : response.body}"
    rescue StandardError
      path = Rails.root.join("data.json")
      puts "Couldn't connect to recommender host, dumping db into #{path} ..."
      File.open(path, "w") do |f|
        f.write(serialized_db)
      end
    end
  end
end
