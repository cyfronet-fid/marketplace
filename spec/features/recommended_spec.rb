# frozen_string_literal: true

require "rails_helper"
require "sentry-ruby"

RSpec.feature "Recommended services", end_user_frontend: true do
  include OmniauthHelper

  it "should display recommended", js: true do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return("localhost:5000"))
    allow(Mp::Application.config).to receive(:is_recommendation_panel).and_return(true)

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }
    response = double(Faraday::Response, status: 200, body: "{ \"recommendations\": #{services_ids} }")

    allow_any_instance_of(Faraday::Connection).to receive(:post).and_return(response)
    expect(Recommender::SimpleRecommender).not_to receive(:new)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq services_ids.length
  end

  it "should not display recommended on is_recommendation_panel set to false", js: true do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return("localhost:5000"))
    allow(Mp::Application.config).to receive(:is_recommendation_panel).and_return(false)

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq 0
  end

  it "should not display recommended on faraday error", js: true do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return("localhost:5000"))

    allow(Faraday).to receive(:post).and_raise(ArgumentError)
    allow(Sentry).to receive(:capture_message)

    services_ids = [1, 2, 3]
    services = services_ids.map { |id| create(:service, id: id) }
    allow(Recommender::SimpleRecommender).to receive_message_chain(:new, :call).and_return(services)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq 0
  end

  it "should display simple recommended services on unknown outer service host", js: true do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    allow(Mp::Application.config).to receive(:is_recommendation_panel).and_return(true)

    services_ids = [1, 2, 3]
    services = services_ids.map { |id| create(:service, id: id) }
    allow(Recommender::SimpleRecommender).to receive_message_chain(:new, :call).and_return(services)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq services_ids.length
  end

  it "should not display recommended on unknown host, when run on production", js: true do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    allow(Rails.env).to receive(:production?).and_return(true)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq 0
  end
end
