# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Services in ordering_configuration panel" do
  include OmniauthHelper

  context "As a data_administrator" do
    let(:user) { create(:user) }
    let(:data_administrator) { create(:data_administrator, email: user.email) }
    let(:provider) { create(:provider, data_administrators: [data_administrator]) }
    let(:service) { create(:service, resource_organisation: provider, offers: [create(:offer)]) }

    before { checkin_sign_in_as(user) }

    scenario "I can see ordering_configuration panel" do
      visit service_ordering_configuration_path(service)

      expect(page).to have_content("Ordering configuration")
      expect(page).to have_content(service.name)
      expect(page).to have_link("Back to the resource")
      expect(page).to have_link("Set parameters and offers")
    end

    scenario "I can edit offer parameters", js: true do
      visit service_ordering_configuration_path(service)

      click_on "Edit parameters"

      find("li", text: "Input").click
      find("#attributes-list-button").first("svg").click

      within("div.card-text") do
        fill_in "Name", with: "new input parameter"
        fill_in "Hint", with: "test"
        fill_in "Unit", with: "days"
        select "integer", from: "Value type"
      end

      click_on "Update Offer"

      service.reload

      expect(service.offers.first.parameters.size).to eq(1)

      parameter = service.offers.first.parameters.first

      expect(parameter.name).to eq("new input parameter")
      expect(parameter.hint).to eq("test")
      expect(parameter.unit).to eq("days")
      expect(parameter.value_type).to eq("integer")
    end

    scenario "I can create new offer", js: true do
      visit service_ordering_configuration_path(service)

      click_on "Add new offer"

      expect {
        fill_in "Name", with: "new offer 1"
        fill_in "Description", with: "test offer"
        find("li", text: "Input").click
        find("#attributes-list-button").first("svg").click

        within("div.card-text") do
          fill_in "Name", with: "new input parameter"
          fill_in "Hint", with: "test"
          fill_in "Unit", with: "days"
          select "integer", from: "Value type"
        end
        click_on "Create Offer"
      }.to change { service.offers.count }.by(1)

      service.reload
      expect(service.offers.last.name).to eq("new offer 1")
    end

    scenario "I cannot delete offer if it's only one" do
      visit service_ordering_configuration_path(service)

      click_on "Edit parameters"

      expect(page).to_not have_link("Delete Offer")
    end

    scenario "I can add an offer if none exists", js: true do
      service_without_offers = create(:service, resource_organisation: provider, offers: [])

      visit service_ordering_configuration_path(service_without_offers)

      expect(page).to have_content("Add new offer")

      click_on "Add new offer"

      expect {
        fill_in "Name", with: "new offer 1"
        fill_in "Description", with: "test offer"
        find("li", text: "Input").click
        find("#attributes-list-button").first("svg").click

        within("div.card-text") do
          fill_in "Name", with: "new input parameter"
          fill_in "Hint", with: "test"
          fill_in "Unit", with: "days"
          select "integer", from: "Value type"
        end
        click_on "Create Offer"
      }.to change { service_without_offers.offers.count }.by(1)

      service_without_offers.reload
      expect(service_without_offers.offers.last.name).to eq("new offer 1")
    end

    scenario "I can delete offer if there are more than 1" do
      create(:offer, service: service)

      service.reload

      visit service_ordering_configuration_path(service)

      within "#offer-#{service.offers.last.id}" do
        click_on "Edit"
      end

      expect(page).to have_link("Delete Offer")

      click_on "Delete Offer"

      expect(page).to have_content("Offer removed successfully")
      expect(service.offers.size).to eq(1)
    end

    scenario "I can edit offer OMS", js: true do
      oms1 = create(:oms, name: "OMS1", custom_params: { "foo": { "mandatory": true, "default": "baz" } })
      oms2 = create(:oms, name: "OMS2", custom_params: {})
      service = create(:service, name: "my service", resource_organisation: provider, status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service, internal: false)
      create(:offer, service: service)

      service.reload

      visit service_ordering_configuration_path(service, from: "backoffice_service")
      first(".btn.btn-outline-secondary.font-weight-bold").click

      check "Use EOSC Portal as the order management platform"
      select "OMS1", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_falsey

      fill_in "Foo", with: "bar"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_truthy
      expect(offer.primary_oms).to eq(oms1)
      expect(offer.oms_params).to eq({ "foo" => "bar" })

      first(".btn.btn-outline-secondary.font-weight-bold").click

      select "OMS2", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.primary_oms).to eq(oms2)
      expect(offer.oms_params).to eq({})
    end

    scenario "I can edit default offer OMS", js: true do
      oms1 = create(:oms, name: "OMS1", custom_params: { "foo": { "mandatory": true, "default": "baz" } })
      oms2 = create(:oms, name: "OMS2", custom_params: {})
      service = create(:service, name: "my service", resource_organisation: provider, status: :draft)
      offer = create(:offer, name: "offer1", description: "desc", service: service, internal: false)

      service.reload

      visit service_ordering_configuration_path(service, from: "backoffice_service")
      first(".btn.btn-outline-secondary.font-weight-bold").click

      check "Use EOSC Portal as the order management platform"
      select "OMS1", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_falsey

      fill_in "Foo", with: "bar"
      click_on "Update Offer"

      offer.reload
      expect(offer.internal).to be_truthy
      expect(offer.primary_oms).to eq(oms1)
      expect(offer.oms_params).to eq({ "foo" => "bar" })

      first(".btn.btn-outline-secondary.font-weight-bold").click

      select "OMS2", from: "Order Management System"
      click_on "Update Offer"

      offer.reload
      expect(offer.primary_oms).to eq(oms2)
      expect(offer.oms_params).to eq({})
    end
  end

  { no: false, service_portfolio_manager: false, admin: false, executive: false }.
    each do |role, authorized|
    context "as an user with #{role} role" do
      let(:user) { create(:user, roles: role == :no ? [] : [role]) }
      let(:provider) { create(:provider) }
      let(:service) { create(:service, resource_organisation: provider, offers: [create(:offer)]) }

      before { checkin_sign_in_as(user) }

      scenario "I am#{authorized ? nil : " not"} authorized to see the ordering_configuration panel" do
        visit service_ordering_configuration_path(service)

        if authorized
          expect(page).to_not have_content("You are not authorized to see this page")
          expect(page).to have_content("Ordering configuration")
          expect(page).to have_content(service.name)
          expect(page).to have_link("Back to the resource")
          expect(page).to have_link("Set parameters and offers")
        else
          expect(page.current_path).to_not eq(service_ordering_configuration_path(service))
          expect(page).to have_content("You are not authorized to see this page")
        end
      end
    end
  end
end
