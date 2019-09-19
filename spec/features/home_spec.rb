# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Home" do
  include OmniauthHelper

  scenario "searching should go to /services with correct query" do
    visit "/"

    fill_in "q", with: "Something"
    click_on(id: "query-submit")

    expect(page).to have_current_path(services_path, ignore_query: true)
    expect(page).to have_selector("#q[value='Something']")
  end

  context "services carousel" do
    let!(:service1) { create(:service, title: "published-service-1", status: :published) }
    let!(:service2) { create(:service, title: "published-service-2", status: :published) }
    let!(:service_draft) { create(:service, title: "draft-service-123", status: :draft) }
    it "should not show not published service at carousel" do
      visit "/"
      expect(page).to have_selector("div.card-title", text: service1.title)
      expect(page).to have_selector("div.card-title", text: service2.title)
      expect(page).not_to have_selector("div.card-title", text: service_draft.title)
    end
    it "should show appropriate descriptions for all services" do
      visit "/"
      popular = page.find(".home-title", text: "Popular services")
      parent = popular.find(:xpath, "..")
      descriptions = parent.all(".card-description")
      expect(descriptions.map(&:text)).to match_array([service1, service2].map(&:description))
    end
  end
end
