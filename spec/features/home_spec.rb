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
    let!(:service1) { create(:service, title: "published-service-123", status: :published) }
    let!(:service2) { create(:service, title: "draft-service-123", status: :draft) }
    it "should not show not published service at carousel" do
      visit "/"
      expect(page).to have_selector("div.card-title", text: "published-service-123")
      expect(page).not_to have_selector("div.card-title", text: "draft-service-123")
    end
  end
end
