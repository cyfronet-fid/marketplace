# frozen_string_literal: true

require "elasticsearch/model"

if ENV["ELASTICSEARCH_URL"]
  Elasticsearch::Model.client = Elasticsearch::Client.new(url: ENV["ELASTICSEARCH_URL"])
end
