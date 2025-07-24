# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Providers in backoffice", manager_frontend: true do
  include OmniauthHelper
  include WebsiteHelper

  context "with JS: As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { checkin_sign_in_as(user) }

    scenario "I can edit provider when upstream is set to MP (nil)",
             js: true,
             skip: "Not valid after provider form refactor" do
      provider = create(:provider, name: "Old name", upstream: nil)
      stub_website_check(provider)

      visit edit_backoffice_provider_path(provider)
      click_on "Basic", match: :first
      expect(page).to have_field "Name", disabled: false

      fill_in "Name", with: "New name"
      click_on "Update Provider"
      sleep(5)
      expect(page).to have_content("Edit")
      expect(page).to have_content("New name")
    end

    scenario "I can not edit provider when upstream is not set to MP (nil)",
             js: true,
             skip: "Not valid after provider form refactor" do
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

    scenario "I can remove data administrator", js: true, skip: "Not valid after provider form refactor" do
      data_administrators = create_list(:data_administrator, 2)
      provider = create(:provider, data_administrators: data_administrators)
      stub_website_check(provider)

      visit edit_backoffice_provider_path(provider)
      expect(page).to have_text("Edit #{provider.name} Provider")

      click_on "Admins", match: :first
      expect(page).to have_css("#data-administrator-delete-0")
      expect(page).to have_css("#data-administrator-delete-1")
      expect(provider.data_administrators.count).to eq(2)

      click_on "data-administrator-delete-0"
      expect(page).to_not have_css("#data-administrator-delete-0")
      expect(page).to have_css("#data-administrator-delete-1")

      click_on "Update Provider"
      expect(page).to have_content("Edit")
      expect(page).to have_content("Delete")
      expect(provider.data_administrators.count).to eq(1)
    end

    scenario "I can delete external source", js: true, skip: true do
      provider = create(:provider)
      _external_source = create(:provider_source, eid: "777abc", source_type: "eosc_registry", provider: provider)
      stub_website_check(provider)
      count = ProviderSource.count

      visit edit_backoffice_provider_path(provider)

      click_on "Other", match: :first
      expect(page).to have_selector(:id, "provider_sources_attributes_0__destroy")
      find("#provider_sources_attributes_0__destroy").click
      click_on "Other", match: :first

      click_on "Update Provider"
      expect(page).to have_content("Provider updated successfully")
      expect(page).to have_content("Delete")
      expect(ProviderSource.count).to eq(count - 1)
    end

    scenario "I can create new provider with data administrators", skip: true, js: true do
      count = ProviderSource.count
      provider = build(:provider)

      visit backoffice_providers_path
      click_on "Add new Provider"
      expect(page).to have_content("New Provider")

      click_on "Basic", match: :first
      expect(page).to have_content("Name")
      fill_in "Name", with: provider.name
      fill_in "Abbreviation", with: provider.abbreviation
      stub_website_check(provider)
      fill_in "Website", with: provider.website

      click_on "Marketing", match: :first
      expect(page).to have_content("Description")
      fill_in "Description", with: provider.description
      page.attach_file("provider_logo", "#{Rails.root}/app/assets/images/eosc-img.png")

      click_on "Location", match: :first
      expect(page).to have_content("Street name and number")

      # fill_in "Street name and number", with: provider.street_name_and_number
      fill_in "provider_street_name_and_number", with: provider.street_name_and_number
      fill_in "Postal code", with: provider.postal_code
      fill_in "City", with: provider.city
      select "non-European", from: "provider_country"

      click_on "Contact", match: :first
      fill_in "provider_main_contact_attributes_first_name", with: "Main first name"
      fill_in "provider_main_contact_attributes_last_name", with: "Main last name"
      fill_in "provider_main_contact_attributes_email", with: "main.contact@mail.com"
      fill_in "provider_public_contacts_attributes_0_email", with: "public.contact@mail.com"

      click_on "Other", match: :first
      fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid

      click_on "Admins", match: :first
      fill_in "provider_data_administrators_attributes_0_first_name", with: "John"
      fill_in "provider_data_administrators_attributes_0_last_name", with: "Doe"
      fill_in "provider_data_administrators_attributes_0_email", with: "john@doe.com"

      click_on "Create Provider"
      expect(page).to have_content("New provider created successfully")
      expect(page).to have_content("Delete")
      expect(ProviderSource.count).to eq(count + 1)
      # expect { click_on "Create Provider" }.to change { Provider.count }.by(1).
      #   and(change { DataAdministrator.count }.by(1))

      # expect(page).to have_content(provider.name)
    end
  end

  context "As a service portolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }
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

    scenario "I can edit data administrator", skip: "Not valid after provider form refactor" do
      data_administrator = create(:data_administrator)
      provider = create(:provider, data_administrators: [data_administrator])
      stub_website_check(provider)

      visit edit_backoffice_provider_path(provider)

      page.attach_file("provider_logo", "#{Rails.root}/app/assets/images/eosc-img.png")

      fill_in "provider_data_administrators_attributes_0_first_name", with: "John"
      fill_in "provider_data_administrators_attributes_0_last_name", with: "Doe"
      fill_in "provider_data_administrators_attributes_0_email", with: "john@doe.com"

      # fill_in "provider_sources_attributes_0_eid", with: provider.sources.first.eid

      click_on "Update Provider"

      data_administrator.reload

      expect(data_administrator.first_name).to eq("John")
      expect(data_administrator.last_name).to eq("Doe")
      expect(data_administrator.email).to eq("john@doe.com")
    end

    scenario "I can create provider with external source", skip: true do
      visit backoffice_providers_path
      click_on "Add new Provider"

      provider = build(:provider)
      fill_in "Name", with: provider.name
      fill_in "Abbreviation", with: provider.abbreviation
      stub_website_check(provider)
      fill_in "Website", with: provider.website
      fill_in "Description", with: provider.description
      page.attach_file("provider_logo", "#{Rails.root}/app/assets/images/eosc-img.png")
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
      expect(page).to have_content("eosc_registry: #{provider.sources.first.eid}")
    end

    scenario "I can change external id of the provider", skip: true do
      provider = create(:provider, name: "Old name")
      _external_source = create(:provider_source, eid: "777abc", source_type: "eosc_registry", provider: provider)

      visit edit_backoffice_provider_path(provider)

      expect(page).to have_selector("input[value='777abc']")
      page.attach_file("provider_logo", "#{Rails.root}/app/assets/images/eosc-img.png")
      fill_in "provider_sources_attributes_0_eid", with: "abc777"
      click_on "Update Provider"
      expect(page).to have_content("eosc_registry: abc777")
    end
  end
end
