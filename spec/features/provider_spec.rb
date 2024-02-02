# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Provider browsing", end_user_frontend: true do
  include OmniauthHelper

  scenario "allows to see provider details" do
    provider = create(:provider)

    visit provider_path(provider)

    expect(body).to have_content provider.name
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

    expect(page).to have_content "Recently added services"
    expect(page).to have_content service.name
  end

  scenario "does not show recent added services section when no related services" do
    provider = create(:provider)

    visit provider_path(provider)

    expect(body).to_not have_content "Recently added services"
  end

  scenario "I can see 'Manage the service' button if i am an admin provider and its eosc_registry" do
    admin = create(:user)
    data_admin =
      create(:data_administrator, first_name: admin.first_name, last_name: admin.last_name, email: admin.email)
    provider = create(:provider, data_administrators: [data_admin])
    provider_source = create(:eosc_registry_provider_source, provider: provider)
    provider.upstream = provider_source
    provider.save!

    checkin_sign_in_as(admin)

    visit provider_path(provider)

    expect(page).to have_link("Browse services")
    expect(page).to have_content("Manage the provider")
  end

  scenario "I cannnot see 'Manage the service' button if it is 'eosc_registry' service and i am not an admin" do
    user, admin = create_list(:user, 2)
    data_admin =
      create(:data_administrator, first_name: admin.first_name, last_name: admin.last_name, email: admin.email)
    provider = create(:provider, data_administrators: [data_admin])
    provider_source = create(:eosc_registry_provider_source, provider: provider)
    provider.upstream = provider_source
    provider.save!

    checkin_sign_in_as(user)

    visit provider_path(provider)

    expect(page).to have_link("Browse services")
    expect(page).to_not have_content("Manage the provider")
  end

  scenario "I cannnot see 'Manage the service' button if it not eosc_registry provider and i am an admin" do
    admin = create(:user)
    data_admin =
      create(:data_administrator, first_name: admin.first_name, last_name: admin.last_name, email: admin.email)
    provider = create(:provider, data_administrators: [data_admin])

    checkin_sign_in_as(admin)

    visit provider_path(provider)

    expect(page).to have_link("Browse services")
    expect(page).to_not have_content("Manage the provider")
  end
end
