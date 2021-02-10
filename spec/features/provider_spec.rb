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
end
