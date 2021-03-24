# frozen_string_literal: true

require "rails_helper"

RSpec.feature "recommended services panel", type: :feature do
  include OmniauthHelper
  include SimpleRecommenderSpecHelper

  before do
    checkin_sign_in_as(create(:user))
    resources_selector = "body main div:nth-child(2).container div.container div.row div.col-lg-9"
    bar_selector = "div.row.mb-4 div:nth-child(2).mb-4"
    recommended_service_selector = "div.container div.row mb-4 div:nth-child(1).service-info-box.recommendation"

    @recommended_services_bar = resources_selector + " " + bar_selector
    @recommended_services = resources_selector + " " + recommended_service_selector

    @categories, @services = populate_database
  end

  it "has no recommendations if they are disabled", js: true do
    use_ab_test(recommendation_panel: "disabled")
    visit services_path

    expect(page).to_not have_content(_("SUGGESTED"))
  end

  it "has header with 'SUGGESTED' box in version 1", js: true do
    use_ab_test(recommendation_panel: "v1")
    visit services_path

    expect(page).to have_content(_("SUGGESTED"))
    expect(find(@recommended_services_bar)).to have_content(_("SUGGESTED"))
  end

  it "has 'SUGGESTED' box in each recommended service in version 2", js: true do
    use_ab_test(recommendation_panel: "v2")
    visit services_path

    expect(page).to have_content(_("SUGGESTED"))
    all(@recommended_services).each do |element|
      expect(element.has_css?(".recommend-box"))
      expect(element).to have_text(_("SUGGESTED"))
      expect(element.has_css?(".image-frame"))
      expect(element).to have_text(_("Organisation") + ":")
      expect(element).to have_text(_("Dedicated for") + ":")
    end
  end
end
