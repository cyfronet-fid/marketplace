# frozen_string_literal: true

require "rails_helper"

RSpec.feature "User action", js: true do
  it "should skip probes recording on unknown recommender host" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    expect(Probes::ProbesJob).to_not receive(:perform_later)

    visit services_path
    first("[data-probe]").click
  end

  it "should update params and call job" do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(
      receive(:recommender_host).and_return("localhost:5000")
    )

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }
    allow(Unirest).to receive(:post).and_return(services_ids)

    expect(Probes::ProbesJob).to receive(:perform_later) do |_, body|
      body = JSON.parse(body)
      expect(body["timestamp"].to_s).to match(/[0-9]+/)

      expect(body["source"]["visit_id"].to_s).to match(/[0-9]+\.[0-9]+\.[a-zA-Z0-9]+\.[0-9]+/)
      expect(body["source"]["page_id"]).to eq "/services"
      expect(body["source"]["root"]["type"]).to eq "other"
      expect(body["source"]["root"]["panel_id"]).to be_nil

      expect(body["target"]["visit_id"].to_s).to match(/[0-9]+\.[0-9]+\.[a-zA-Z0-9]+\.[0-9]+/)
      expect(body["target"]["page_id"].to_s).to match(/(\/[a-zA-Z0-9_-])+/)

      expect(body["action"]["order"]).to be_nil

      expect(body["unique_id"].to_s).to match(/[a-zA-Z0-9]+\.[0-9]+/)
    end

    visit services_path
    first("a[data-probe]").click
  end
end
