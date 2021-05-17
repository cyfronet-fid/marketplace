# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Providers in backoffice" do
  include OmniauthHelper

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:service_portfolio_manager]) }
    before { checkin_sign_in_as(user) }

    scenario "I can see all providers" do
      create(:provider, name: "p1")
      create(:provider, name: "p2")

      visit backoffice_providers_path

      expect(page).to have_content("p1")
      expect(page).to have_content("p2")
    end

    scenario "I can see provider details" do
      child = create(:provider, name: "my provider")

      visit backoffice_provider_path(child)

      expect(page).to have_content("my provider")
    end

    scenario "I can create new provider with data administrators" do
      visit backoffice_providers_path
      click_on "Add new Provider"

      provider = build(:provider)
      fill_in "Name", with: provider.name
      fill_in "Abbreviation", with: provider.abbreviation

      stub_request(:get, provider.website).
        with(headers: {
          "Accept": "*/*",
          "User-Agent": "unirest-ruby/1.0",
          "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host": provider.website.gsub(/http(s?):\/\//, "")
        }).
        to_return(status: 200, body: "", headers: {})
      fill_in "Website", with: provider.website

      fill_in "Description", with: provider.description
      page.attach_file("provider_logo", "#{Rails.root}/app/javascript/images/eosc-img.png")
      fill_in "Street name and number", with: provider.street_name_and_number
      fill_in "Postal code", with: provider.postal_code
      fill_in "City", with: provider.city
      select "non-European", from: "provider_country"

      fill_in "provider_main_contact_attributes_first_name", with: "Main first name"
      fill_in "provider_main_contact_attributes_last_name", with: "Main last name"
      fill_in "provider_main_contact_attributes_email", with: "main.contact@mail.com"
      fill_in "provider_public_contacts_attributes_0_email", with: "public.contact@mail.com"

      click_on "Admins", match: :first

      fill_in "provider_data_administrators_attributes_0_first_name", with: "John"
      fill_in "provider_data_administrators_attributes_0_last_name", with: "Doe"
      fill_in "provider_data_administrators_attributes_0_email", with: "john@doe.com"

      fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid

      expect { click_on "Create Provider" }.to change { Provider.count }.by(1).
        and(change { DataAdministrator.count }.by(1))

      expect(page).to have_content(provider.name)
    end

    scenario "I can edit provider when upstream is set to MP (nil)", js: true  do
      provider = create(:provider, name: "Old name", upstream: nil)
      stub_request(:get, provider.website).
        with(headers: {
          "Accept": "*/*",
          "User-Agent": "unirest-ruby/1.0",
          "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host": provider.website.gsub(/http(s?):\/\//, "")
        }).
        to_return(status: 200, body: "", headers: {})

      visit edit_backoffice_provider_path(provider)

      click_on "Basic", match: :first
      expect(page).to have_field "Name", disabled: false

      fill_in "Name", with: "New name"
      click_on "Update Provider"

      expect(page).to have_content("New name")
    end

    scenario "I can not edit provider when upstream is not set to MP (nil)", js: true  do
      provider = create(:provider, name: "Old name")
      provider_source = create(:provider_source, provider: provider)
      provider.upstream = provider_source
      provider.save!

      visit edit_backoffice_provider_path(provider)

      click_on "Basic", match: :first

      expect(page).to have_field "Name", disabled: true
      expect(page).to have_field "Abbreviation", disabled: true
      expect(page).to have_field "Website", disabled: true
      expect(page).to have_field "Legal entity", disabled: true
    end

    scenario "I can edit data administrator" do
      data_administrator = create(:data_administrator)
      provider = create(:provider, data_administrators: [data_administrator])
      stub_request(:get, provider.website).
        with(headers: {
          "Accept": "*/*",
          "User-Agent": "unirest-ruby/1.0",
          "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host": provider.website.gsub(/http(s?):\/\//, "")
        }).
        to_return(status: 200, body: "", headers: {})

      visit edit_backoffice_provider_path(provider)

      page.attach_file("provider_logo", "#{Rails.root}/app/javascript/images/eosc-img.png")

      fill_in "provider_data_administrators_attributes_0_first_name", with: "John"
      fill_in "provider_data_administrators_attributes_0_last_name", with: "Doe"
      fill_in "provider_data_administrators_attributes_0_email", with: "john@doe.com"

      fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid

      click_on "Update Provider"

      data_administrator.reload

      expect(data_administrator.first_name).to eq("John")
      expect(data_administrator.last_name).to eq("Doe")
      expect(data_administrator.email).to eq("john@doe.com")
    end

    # Test fail when run in stack, single run succeed
    scenario "I can remove data administrator", js: true, skip: true do
      data_administrators = create_list(:data_administrator, 2)
      provider = create(:provider, data_administrators: data_administrators)

      visit edit_backoffice_provider_path(provider)

      click_on "Admins", match: :first

      expect(page).to have_css("#data-administrator-delete-0")
      expect(page).to have_css("#data-administrator-delete-1")

      click_on "data-administrator-delete-0"

      expect { click_on "Update Provider" }.
        to change { ProviderDataAdministrator.count }.by(-1).
          and(change { provider.data_administrators.count }.by(-1))
    end

    scenario "I can create provider with external source" do
      visit backoffice_providers_path
      click_on "Add new Provider"

      provider = build(:provider)
      fill_in "Name", with: provider.name
      fill_in "Abbreviation", with: provider.abbreviation
      stub_request(:get, provider.website).
        with(headers: {
          "Accept": "*/*",
          "User-Agent": "unirest-ruby/1.0",
          "Accept-Encoding": "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
          "Host": provider.website.gsub(/http(s?):\/\//, "")
        }).
        to_return(status: 200, body: "", headers: {})
      fill_in "Website", with: provider.website
      fill_in "Description", with: provider.description
      page.attach_file("provider_logo", "#{Rails.root}/app/javascript/images/eosc-img.png")
      fill_in "Street name and number", with: provider.street_name_and_number
      fill_in "Postal code", with: provider.postal_code
      fill_in "City", with: provider.city
      select "non-European", from: "provider_country"

      fill_in "provider_main_contact_attributes_first_name", with: "Main first name"
      fill_in "provider_main_contact_attributes_last_name", with: "Main last name"
      fill_in "provider_main_contact_attributes_email", with: "main.contact@mail.com"
      fill_in "provider_public_contacts_attributes_0_email", with: "public.contact@mail.com"
      fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid

      expect { click_on "Create Provider" }.to change { Provider.count }.by(1)

      expect(page).to have_content(provider.name)
      expect(page).to have_content("eic: #{ provider.sources.first.eid }")
    end

    scenario "I can change external id of the provider" do
      provider = create(:provider, name: "Old name")
      _external_source = create(:provider_source, eid: "777abc", source_type: "eic", provider: provider)

      visit edit_backoffice_provider_path(provider)

      expect(page).to have_selector("input[value='777abc']")
      page.attach_file("provider_logo", "#{Rails.root}/app/javascript/images/eosc-img.png")
      fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid
      click_on "Update Provider"
      expect(page).to have_content("eic: #{ provider.sources.first.eid }")
    end

    # Test fail when run in stack, single run succeed
    scenario "I can delete external source", skip: true do
      provider = create(:provider)
      _external_source = create(:provider_source, eid: "777abc", source_type: "eic", provider: provider)

      visit edit_backoffice_provider_path(provider)
      page.attach_file("provider_logo", "#{Rails.root}/app/javascript/images/eosc-img.png")
      find(:css, "#provider_sources_attributes_0__destroy").set(true)
      expect { click_on "Update Provider" }.to change { ProviderSource.count }.by(-1)
    end
  end
end
