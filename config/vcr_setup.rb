# frozen_string_literal: true
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/fixtures"
  config.hook_into :webmock
  config.default_cassette_options = {
    serialize_with: :json
  }
  config.allow_http_connections_when_no_cassette = true
end
