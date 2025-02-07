# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Categories in backoffice", manager_frontend: true do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see all categories" do
      create(:category, name: "c1")
      create(:category, name: "c2")

      visit backoffice_other_settings_categories_path

      expect(page).to have_content("c1")
      expect(page).to have_content("c2")
    end

    scenario "I can see category details" do
      parent = create(:category, name: "parent")
      child = create(:category, name: "child", parent: parent)

      visit backoffice_other_settings_category_path(child)

      expect(page).to have_content("child")
      expect(page).to have_content("parent")
    end

    scenario "I can create new category" do
      create(:category, name: "parent")

      visit backoffice_other_settings_categories_path
      click_on "Add new Category"

      fill_in "Name", with: "My new category"
      select "parent", from: "Parent"

      expect { click_on "Create Category" }.to change { Category.count }.by(1)

      expect(page).to have_content("My new category")
      expect(page).to have_content("parent")
    end

    scenario "I can edit category" do
      create(:category, name: "parent")
      category = create(:category, name: "Old name")

      visit edit_backoffice_other_settings_category_path(category)

      fill_in "Name", with: "New name"
      select "parent", from: "Parent"
      click_on "Update Category"

      expect(page).to have_content("New name")
      expect(page).to have_content("parent")
    end
  end
end
