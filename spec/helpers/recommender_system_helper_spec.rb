# frozen_string_literal: true

require "rails_helper"

RSpec.describe RecommenderSystemHelper, type: :helper do
  xit "returns list of 3 services for version 1 of recommendation" do
    use_ab_test(recommendation_panel: "v1")

    recommended_services = get_naive_recommendation
    expect(recommended_services.count).to eq 3
  end

  xit "returns list of 2 services for version 2 of recommendation" do
    use_ab_test(recommendation_panel: "v2")

    recommended_services = get_naive_recommendation
    expect(recommended_services.count).to eq 2
  end
end
