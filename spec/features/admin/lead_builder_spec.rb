# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Marketplace lead builder", manager_frontend: true do
  include OmniauthHelper

  let(:admin) { create(:user, roles: [:admin]) }

  before { checkin_sign_in_as(admin) }

  context "lead section" do
    scenario "can be created" do
      visit admin_leads_path

      click_on "Add new lead section"
      fill_in "Title", with: "Learn more"
      select "learn_more", from: "Template"
      fill_in "Slug", with: "slug1"
      click_on "Create Lead section"

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to have_content("Learn more")
    end

    scenario "can be updated" do
      section = create(:lead_section)

      visit edit_admin_lead_section_path(section)

      fill_in "Title", with: "Updated section title"
      click_on "Update Lead section"

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to have_content("Updated section title")
    end

    scenario "can be deleted", js: true do
      section = create(:lead_section)

      visit admin_leads_path

      find("#delete-lead-section-#{section.id}").click
      find("#confirm-accept").click

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to_not have_content(section.title)
    end
  end

  context "lead", js: true do
    let!(:section) { create(:lead_section) }

    scenario "can be created" do
      visit admin_leads_path

      find("#add-new-lead-#{section.id}").click
      fill_in "Header", with: "New header"
      fill_in "Body", with: "New body"
      fill_in "Url", with: "https://test.test"
      attach_file("lead[picture]", File.join(Rails.root, "spec", "factories", "images", "test.png"), visible: false)
      click_on "Create Lead"

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to have_css("img[src*='.png']")
      expect(page).to have_content("New header")
      expect(page).to have_content("New body")
    end

    scenario "can be updated" do
      item = create(:lead, lead_section: section)

      visit edit_admin_lead_path(item)
      fill_in "Header", with: "Updated header"
      fill_in "Body", with: "Updated body"
      attach_file("lead[picture]", File.join(Rails.root, "spec", "factories", "images", "test.png"), visible: false)

      click_on "Update Lead"

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to have_content("Updated header")
      expect(page).to have_content("Updated body")
    end

    scenario "can be deleted", js: true do
      item = create(:lead, lead_section: section)

      visit admin_leads_path

      find("#delete-lead-#{item.id}").click
      find("#confirm-accept").click

      expect(page).to have_current_path(admin_leads_path)
      expect(page).to_not have_content(item.header)
    end

    scenario "cannot be created without picture", skip: true, js: true do
      visit admin_leads_path

      find("#add-new-lead-#{section.id}").click
      fill_in "Header", with: "New header"
      fill_in "Body", with: "New body"
      fill_in "Url", with: "https://test.test"
      click_on "Create Lead"

      expect(page).to have_content("Picture can't be blank")
    end
  end
end
