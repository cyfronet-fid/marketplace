# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Scientific domains in backoffice", manager_frontend: true do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all scientific domains" do
      create(:scientific_domain, name: "ra1")
      create(:scientific_domain, name: "ra2")

      visit backoffice_other_settings_scientific_domains_path

      expect(page).to have_content("ra1")
      expect(page).to have_content("ra2")
    end

    scenario "I can see scientific domain details" do
      parent = create(:scientific_domain, name: "parent")
      child = create(:scientific_domain, name: "child", parent: parent)

      visit backoffice_other_settings_scientific_domain_path(child)

      expect(page).to have_content("child")
      expect(page).to have_content("parent")
    end

    scenario "I can create new scientific domain" do
      create(:scientific_domain, name: "parent")

      visit backoffice_other_settings_scientific_domains_path
      click_on "Add new Scientific Domain"

      fill_in "Name", with: "My new scientific domain"
      select "parent", from: "Parent"

      expect { click_on "Create Scientific domain" }.to change { ScientificDomain.count }.by(1)

      expect(page).to have_content("My new scientific domain")
      expect(page).to have_content("parent")
    end

    scenario "I can edit scientific domain" do
      create(:scientific_domain, name: "parent")
      scientific_domain = create(:scientific_domain, name: "Old name")

      visit edit_backoffice_other_settings_scientific_domain_path(scientific_domain)

      fill_in "Name", with: "New name"
      select "parent", from: "Parent"
      click_on "Update Scientific domain"

      expect(page).to have_content("New name")
      expect(page).to have_content("parent")
    end
  end
end
