# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Marketplace help builder", manager_frontend: true do
  include OmniauthHelper

  let(:admin) { create(:user, roles: [:admin]) }

  before { checkin_sign_in_as(admin) }

  context "help section" do
    scenario "can be created", js: true do
      visit admin_help_path

      click_on "+ add new help section"
      fill_in "Title", with: "Ordering process"
      click_on "Create Help section"

      expect(page).to have_current_path(admin_help_path)
      expect(page).to have_content("Ordering process")
    end

    scenario "can be updated" do
      section = create(:help_section)

      visit edit_admin_help_section_path(section)

      fill_in "Title", with: "Updated section title"
      click_on "Update Help section"

      expect(page).to have_current_path(admin_help_path)
      expect(page).to have_content("Updated section title")
    end

    scenario "can be deleted", js: true do
      section = create(:help_section)

      visit admin_help_path

      find(".delete-icon").click
      find("#confirm-accept").click

      expect(page).to have_current_path(admin_help_path)
      expect(page).to_not have_content(section.title)
    end
  end

  context "help item", js: true do
    let!(:section) { create(:help_section) }

    scenario "can be created" do
      visit admin_help_path

      click_on "+ add new item"
      fill_in "Title", with: "How to order a service"
      find("trix-editor").click.set("It is quite simple")
      click_on "Create Help item"

      expect(page).to have_current_path(admin_help_path)
      expect(page).to have_content("How to order a service")
      click_on "How to order a service"
      expect(page).to have_content("It is quite simple")
    end

    scenario "can be updated" do
      item = create(:help_item, help_section: section)

      visit edit_admin_help_item_path(item)
      fill_in "Title", with: "Updated item title"
      find("trix-editor").click.set("Update item content")
      click_on "Update Help item"

      expect(page).to have_current_path(admin_help_path)
      expect(page).to have_content("Updated item title")
      click_on "Updated item title"
      expect(page).to have_content("Update item content")
    end

    scenario "can be deleted", js: true do
      item = create(:help_item, help_section: section)

      visit admin_help_path

      find("#delete-lead-#{section.id}").click
      find("#confirm-accept").click

      expect(page).to have_current_path(admin_help_path)
      expect(page).to_not have_content(item.title)
    end
  end
end
