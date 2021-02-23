# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Recommended services" do
  include OmniauthHelper

  it "should display recommended", js: true do
    use_ab_test(recommendation_panel: "v1")
    allow(Mp::Application.config).to(
      receive(:recommender_host).and_return("localhost:5000")
    )

    services_ids = [1, 2, 3]
    services_ids.each { |id| create(:service, id: id) }
    allow(Unirest).to receive(:post).and_return(services_ids)

    visit services_path

    expect(all("[data-probe='recommendation-panel']").length).to be services_ids.length
  end
end
