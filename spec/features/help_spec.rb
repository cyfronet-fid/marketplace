# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Help" do
  include OmniauthHelper

  scenario "anonynous user is redirected to old help page" do
    visit help_path

    expect(page).to have_current_path(page_path("help"))
  end

  scenario "non admin user is redirected to old help page" do
    checkin_sign_in_as(create(:user))

    visit help_path

    expect(page).to have_current_path(page_path("help"))
  end

  context "as admin" do
    let(:admin) { create(:user, roles: [:admin]) }

    before { checkin_sign_in_as(admin) }

    scenario "I can see gemerated help page" do
      section = create(:help_section)
      item = create(:help_item, help_section: section, content: "Help item content")

      visit help_path

      expect(page).to have_content(section.title)
      expect(page).to have_content(item.title)
      click_on item.title
      expect(page).to have_content("Help item content")
    end
  end
end
