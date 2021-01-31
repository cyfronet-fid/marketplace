# frozen_string_literal: true

require "recommender/serialize_db"

namespace :recommender do
  desc "serialize database for recommender system"
  task serialize_db: :environment do
    serialized_db = Recommender::SerializeDb.new.call

    # TODO: We are writing to a file now. Later we will send this to the recommender db endpoint
    File.open("data.json", "w") do |f|
      f.write(serialized_db.to_json)
    end
  end
end
