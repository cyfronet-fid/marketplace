# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::OffersController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/offers" do
    get "lists published offers" do
      tags "offers"
      produces "application/json"
      security [authentication_token: []]

      response 200, "offer found" do
        schema "$ref" => "ess/offer/offer_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:offers) { create_list(:offer, 2) }
        let!(:second_offer) { create(:offer, service_id: offers.first.service_id) }
        let!(:draft_service) { create(:service, status: :draft) }
        let!(:published_offer_draft_service) { create(:offer, service: draft_service) }
        let!(:draft) { create(:offer, service_id: offers.second.service_id, status: :draft) }
        let!(:deleted) { create(:offer, status: :deleted) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          expected = offers << second_offer
          data = JSON.parse(response.body)
          expect(data.length).to eq(expected.size)
          expect(data).to match_array(expected&.map { |s| Ess::OfferSerializer.new(s).as_json.deep_stringify_keys })
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:offers) { create_list(:offer, 3) }
        let!(:second_offer) { create(:offer, service_id: offers.first.service_id) }
        let!(:draft) { create(:offer, service_id: offers.second.service_id, status: :draft) }
        let!(:deleted) { create(:offer, status: :deleted) }

        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end

  path "/api/v1/ess/offers/{offer_id}" do
    parameter name: :offer_id, in: :path, type: :string, description: "Offer identifier id"

    get "retrieves a offer by id" do
      tags "offers"
      produces "application/json"
      security [authentication_token: []]

      response 200, "offer found by id" do
        schema "$ref" => "ess/offer/offer_read.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:offer) { create(:offer) }

        let(:offer_id) { offer.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(Ess::OfferSerializer.new(offer).as_json.deep_stringify_keys)
        end
      end

      response 404, "draft offer not found by id" do
        schema "$ref" => "error.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:offer) { create(:offer, status: :draft) }

        let(:offer_id) { offer.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Resource not found" }.deep_stringify_keys)
        end
      end

      response 403, "offer not found by unpermitted user" do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:offer) { create(:offer, status: :draft) }

        let(:offer_id) { offer.id }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:offer_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
