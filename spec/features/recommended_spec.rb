# frozen_string_literal: true

require "rails_helper"
require "raven"

RSpec.feature "Recommended services" do
  include OmniauthHelper

  it "should display recommended", js: true do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(
      receive(:recommender_host).and_return("localhost:5000")
    )

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }
    allow(Unirest).to receive(:post).and_return(double(code: 200, body: { "recommendations" => services_ids }))
    expect(Recommender::SimpleRecommender).not_to receive(:new)

    visit services_path
    expect(all("[data-probe=\"recommendation-panel\"]").length).to be services_ids.length
  end

  it "should not display recommended on unirest error", js: true do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(
      receive(:recommender_host).and_return("localhost:5000")
    )

    allow(Unirest).to receive(:post).and_raise(ArgumentError)
    allow(Raven).to receive(:capture_message)

    services_ids = [1, 2, 3]
    services = services_ids.map { |id| create(:service, id: id) }
    allow(Recommender::SimpleRecommender).to receive_message_chain(:new, :call).and_return(services)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq 0
  end

  it "should display simple recommended services on unknown outer service host", js: true do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))

    services_ids = [1, 2, 3]
    services = services_ids.map { |id| create(:service, id: id) }
    allow(Recommender::SimpleRecommender).to receive_message_chain(:new, :call).and_return(services)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq services_ids.length
  end

  it "should not display recommended on unknown host, when run on production", js: true do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(receive(:recommender_host).and_return(nil))
    allow(Rails.env).to receive(:production?).and_return(true)

    visit services_path
    expect(all("[data-probe='recommendation-panel']").length).to eq 0
  end
end
