# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::ServicesController", backend: true do
  let!(:published_service) { create(:service, public_contacts: [build(:public_contact)]) }
  let!(:second_service) { create(:service, public_contacts: [build(:public_contact)], status: :published) }
  let!(:draft_service) { create(:service, public_contacts: [build(:public_contact)], status: :draft) }
  let!(:deleted_service) { create(:service, public_contacts: [build(:public_contact)], status: :deleted) }
  let!(:errored_service) { create(:service, public_contacts: [build(:public_contact)], status: :errored) }

  describe "GET /api/services" do
    before(:each) { get api_services_api_path }

    it "have 200 status code response" do
      expect(response).to have_http_status(:ok)
      expect(response.header["Content-Type"]).to eq("application/json; charset=utf-8")
    end

    it "shows only published services with correct data" do
      body = JSON.parse(response.body)
      expect(body.size).to eq(2)

      expect(body[0].keys).to contain_exactly(
        "Service Unique ID",
        "SERVICE_TYPE",
        "CONTACT_EMAIL",
        "SITENAME-SERVICEGROUP",
        "COUNTRY_NAME",
        "URL"
      )

      expect(body[0]["Service Unique ID"]).to eq(published_service.id)
      expect(body[0]["SERVICE_TYPE"]).to eq("eu.eosc.portal.services.url")
      expect(body[0]["CONTACT_EMAIL"]).to eq(published_service.public_contacts.map(&:email))
      expect(body[0]["SITENAME-SERVICEGROUP"]).to eq(published_service.name)
      expect(body[0]["COUNTRY_NAME"]).to eq(published_service.geographical_availabilities.as_json)
      expect(body[0]["URL"]).to eq(published_service.webpage_url)

      expect(body[1].keys).to contain_exactly(
        "Service Unique ID",
        "SERVICE_TYPE",
        "CONTACT_EMAIL",
        "SITENAME-SERVICEGROUP",
        "COUNTRY_NAME",
        "URL"
      )

      expect(body[1]["Service Unique ID"]).to eq(second_service.id)
      expect(body[1]["SERVICE_TYPE"]).to eq("eu.eosc.portal.services.url")
      expect(body[1]["CONTACT_EMAIL"]).to eq(second_service.public_contacts.map(&:email))
      expect(body[1]["SITENAME-SERVICEGROUP"]).to eq(second_service.name)
      expect(body[1]["COUNTRY_NAME"]).to eq(second_service.geographical_availabilities.as_json)
      expect(body[1]["URL"]).to eq(second_service.webpage_url)
    end
  end
end
