# frozen_string_literal: true

# config/initializers/elasticsearch.rb

require "elasticsearch/model"

if ENV["ELASTICSEARCH_URL"]
  Elasticsearch::Model.client = Elasticsearch::Client.new(url: ENV["ELASTICSEARCH_URL"])
end
