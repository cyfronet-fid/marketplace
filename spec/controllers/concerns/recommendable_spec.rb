# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller do
    attr_accessor :params
    include Service::Recommendable
  end

  let!(:params) { ActionController::Parameters.new }
  let!(:active_filters) { [] }

  before(:each) do
    controller.params = params

    @panel_id = "v1"
    use_ab_test(recommendation_panel: @panel_id)
  end

  it "Should use simple recommender on unknown recommender host" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    expect(Recommender::SimpleRecommender).to receive(:new).and_call_original

    controller.fetch_recommended
  end

  it "Should fetch recommended service ids" do
    allow(Mp::Application.config).to(
      receive(:recommender_host).and_return("localhost:5000")
    )

    services_ids = [1, 2, 3, 4, 5]
    allow(Unirest).to receive(:post).and_return(services_ids)
    expect(Unirest).to receive(:post) do |_, _, body|
      body = JSON.parse(body)
      expect(body["timestamp"]).to match(/[0-9]+/)
      expect(body["unique_id"]).to match(/[a-zA-Z0-9]{10}\.[0-9]+/)
      expect(body["visit_id"]).to match(/[a-zA-Z0-9]{10}\.[0-9]+\.[0-9]+/)
      expect(body["page_id"]).to eq "/service"
      expect(body["panel_id"]).to eq @panel_id
      expect(body["search_phrase"]).to be nil
      expect(body["logged_user"]).to be false
      expect(body["filters"]).to be nil
    end

    controller.fetch_recommended
  end
end
