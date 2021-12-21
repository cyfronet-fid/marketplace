# frozen_string_literal: true

class MockResponse
  attr_accessor :code, :message, :headers
end

FactoryBot.define do
  factory :response, class: MockResponse do
    skip_create
    transient do
      code { "200" }
      message { "" }
      headers { {} }
    end

    initialize_with do
      r = MockResponse.new
      r.code = code
      r.message = message
      r.headers = headers
      next r
    end
  end
end
