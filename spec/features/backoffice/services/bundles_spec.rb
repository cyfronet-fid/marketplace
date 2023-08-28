# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Bundles in backoffice", manager_frontend: true do
  include OmniauthHelper
  include ExternalServiceDataHelper

  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:owner) { create(:user) }
  let(:data_manager) { create(:user) }
  let(:provider) { build(:provider, data_administrators: [build(:data_administrator, email: data_manager.email)]) }
  let(:service) { create(:service_with_offers, owners: [owner], resource_organisation: provider) }
  let(:offer) { create(:offer) }
  let(:bundle) { build(:bundle, main_offer: service.offers.first, offers: [offer], service: service) }
  let(:scientific_domain) { bundle.scientific_domains.first }

  %i[service_portfolio_manager owner].each do |user|
    context "As a #{user}" do
      before do
        checkin_sign_in_as(send(user))
        stub_external_data
      end

      pending "I can create new bundle" do
        visit backoffice_service_path(service)
        click_on "Add new bundle", match: :first

        fill_in "Name", with: bundle.name

        select bundle.bundle_goals.first.name, from: "Bundle goals"
        select bundle.capabilities_of_goals.first.name, from: "Capabilities of goals"
        select bundle.main_offer.name, from: "Main offer"
        fill_in "Description", with: bundle.description
        select bundle.target_users.first.name, from: "Target users"
        select "#{scientific_domain.parent.name} ⇒ #{scientific_domain.name}", from: "Scientific domains"
        select bundle.research_steps.first.name, from: "Research steps"
        select "#{offer.service.name} > #{offer.name}", from: "Offers"
        fill_in "Helpdesk url", with: bundle.helpdesk_url

        expect { click_on "Create Bundle" }.to change { Bundle.count }.by(1)
        expect(page).to have_content("New bundle created successfully")
      end

      scenario "I can update bundle" do
        bundle.save
        second_offer = create(:offer)
        visit backoffice_service_path(service)

        within("#bundle-#{bundle.iid}") { click_on "Edit" }

        fill_in "Name", with: "#{bundle.name} updated"
        select bundle.main_offer.name, from: "Main offer"
        fill_in "Description", with: "#{bundle.description} updated"
        select "#{second_offer.service.name} > #{second_offer.name}", from: "Offers"

        expect { click_on "Update Bundle" }.to_not change { Bundle.count }

        expect(page).to have_content("Bundle updated successfully")

        expect(page).to have_content("#{bundle.name} updated")
        expect(page).to have_content("#{bundle.description} updated")
        expect(page).to have_content("#{second_offer.name}")
      end
    end
  end
end
