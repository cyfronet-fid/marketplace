# frozen_string_literal: true

require "rails_helper"

RSpec.feature "User action", js: true, end_user_frontend: true do
  it "should skip probes recording on unknown recommender_lib host" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    expect(Probes::ProbesJob).to_not receive(:perform_later)

    visit services_path
    first("[data-probe]").click
  end

  # due to redirections on page some events are triggered few times
  xit "should update params and call job" do
    allow(Mp::Application.config).to(receive(:recommender_host).and_return("localhost:5000"))

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }
    allow(Faraday).to receive(:post).and_return(double(status: 200, body: { "recommendations" => services_ids }))

    expect(Probes::ProbesJob).to receive(:perform_later) do |body|
      body = JSON.parse(body)
      expect(body["timestamp"].to_s).not_to be_nil

      expect(body["source"]["visit_id"].to_s).not_to be_nil
      expect(body["source"]["page_id"]).not_to be_nil
      expect(body["source"]["root"]["type"]).to eq "other"
      expect(body["source"]["root"]["panel_id"]).to be_nil

      expect(body["target"]["visit_id"].to_s).not_to be_nil
      expect(body["target"]["page_id"].to_s).not_to be_nil

      expect(body["action"]["order"]).to be false

      expect(body["unique_id"].to_s).not_to be_nil
    end

    visit services_path
  end
end
