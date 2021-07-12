# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Provider browsing" do
  include OmniauthHelper

  scenario "allows to see provider details" do
    provider = create(:provider)

    visit provider_path(provider)

    expect(body).to have_content provider.name
  end

  scenario "shows providers coverage" do
    provider = create(:provider, participating_countries: %w( PL DE ))

    visit provider_path(provider)

    expect(page).to have_content "Provider coverage"
  end

  scenario "does not show coverage when no countries" do
    provider = create(:provider)

    visit provider_path(provider)

    expect(page).to_not have_content "Provider coverage"
  end

  scenario "shows providers services" do
    provider = create(:provider)
    service = create(:service, providers: [provider])

    visit provider_path(provider)

    expect(page).to have_content "Recently added resources"
    expect(page).to have_content service.name
  end

  scenario "does not show recent added services section when no related services" do
    provider = create(:provider)

    visit provider_path(provider)

    expect(body).to_not have_content "Recently added resources"
  end

  scenario "I can see 'Manage the resource' button if i am an admin provider" do
    admin = create(:user)
    dataAdmin = create(:data_administrator, first_name: admin.first_name, last_name: admin.last_name, email: admin.email)
    provider = create(:provider, data_administrators: [dataAdmin])

    checkin_sign_in_as(admin)

    visit provider_path(provider)

    expect(page).to have_link("Browse resources")
    expect(page).to have_content("Manage the provider")
  end

  scenario "I cannnot see 'Manage the resource' button if i am not an admin provider" do
    user, admin = create_list(:user, 2)
    dataAdmin = create(:data_administrator, first_name: admin.first_name, last_name: admin.last_name, email: admin.email)
    provider = create(:provider, data_administrators: [dataAdmin])

    checkin_sign_in_as(user)

    visit provider_path(provider)

    expect(page).to have_link("Browse resources")
    expect(page).to_not have_content("Manage the provider")
  end
end
