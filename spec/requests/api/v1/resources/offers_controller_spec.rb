# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Resources::OffersController, swagger_doc: "v1/offering_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  before(:each) do
    create(:oms, default: true)
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/resources/{resource_id}/offers" do
    get "lists offers for an administered resource" do
      tags "Offers"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"

      response 200, "offers found" do
        schema "$ref" => "offer/offer_index.json"

        let(:published_offer1) { build(:offer_with_all_parameters) }
        let(:published_offer2) { build(:offer_with_all_parameters) }
        let(:draft_offer) { build(:offer, status: "draft") }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [published_offer1, published_offer2, draft_offer]) }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["offers"].length).to eq(2)

          expect(data["offers"][0]["id"]).to eq(published_offer1.iid)
          expect(data["offers"][0]["name"]).to eq(published_offer1.name)
          expect(data["offers"][0]["description"]).to eq(published_offer1.description)
          expect(data["offers"][0]["parameters"].length).to eq(published_offer1.parameters.length)
          expect(data["offers"][0]["parameters"][0]["type"]).to eq(published_offer1.parameters.first.type)
          expect(data["offers"][0]["parameters"][-1]["type"]).to eq(published_offer1.parameters.last.type)

          expect(data["offers"][1]["id"]).to eq(published_offer2.iid)
          expect(data["offers"][1]["name"]).to eq(published_offer2.name)
          expect(data["offers"][1]["description"]).to eq(published_offer2.description)
          expect(data["offers"][1]["parameters"].length).to eq(published_offer2.parameters.length)
          expect(data["offers"][1]["parameters"][0]["type"]).to eq(published_offer2.parameters.first.type)
          expect(data["offers"][1]["parameters"][-1]["type"]).to eq(published_offer2.parameters.last.type)
        end
      end

      response 200, "offers found but were empty", document: false do
        schema "$ref" => "offer/offer_index.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator])) }

        let(:diff_data_admin_user) { create(:user) }
        let!(:diff_data_administrator) { create(:data_administrator, email: diff_data_admin_user.email) }

        let(:"X-User-Token") { diff_data_admin_user.authentication_token }
        let(:resource_id) { service.slug }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["offers"]).to eq([])
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:resource_id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 404, "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:resource_id) { "definitely-doesnt-exist" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end
    end

    post "creates an offer for an administered resource" do
      tags "Offers"
      produces "application/json"
      consumes "application/json"
      security [ authentication_token: [] ]
      parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
      parameter name: :offer_payload, in: :body, schema: { "$ref" => "offer/offer_write.json" }

      response 201, "offer created" do
        schema "$ref" => "offer/offer_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:offer) { build(:offer_with_all_parameters) }
        let(:offer_payload) { JSON.parse(Api::V1::OfferSerializer.new(offer).to_json) }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer.name)
          expect(service.offers.first.description).to eq(offer.description)
          expect(service.offers.first.status).to eq("published")
          expect(service.offers.first.order_type).to eq(offer.order_type)
          expect(service.offers.first.parameters.size).to eq(offer.parameters.size)
        end
      end

      response 201, "minimalistic offer created", document: false do
        schema "$ref" => "offer/offer_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                order_type: "order_required" } }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer_payload[:name])
          expect(service.offers.first.description).to eq(offer_payload[:description])
          expect(service.offers.first.order_type).to eq(offer_payload[:order_type])
          expect(service.offers.first.status).to eq("published")
        end
      end

      response 201, "offer with oms_params created", document: false do
        schema "$ref" => "offer/offer_read.json"

        let(:oms) { create(:oms, type: :global, custom_params: { "a": { mandatory: true, default: "qwe" } }) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                order_type: "order_required",
                                primary_oms_id: oms.id,
                                oms_params: { "a": "asd" }
        } }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer_payload[:name])
          expect(service.offers.first.description).to eq(offer_payload[:description])
          expect(service.offers.first.order_type).to eq(offer_payload[:order_type])
          expect(service.offers.first.status).to eq("published")
          expect(service.offers.first.primary_oms).to eq(oms)
          expect(service.offers.first.oms_params).to eq({ "a": "asd" }.deep_stringify_keys)
        end
      end

      response 400, "bad request" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
            name: "New offer",
            description: "asd",
            order_type: "lol" } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 400, "fails json validation on non-existent primary_oms_id", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                order_type: "order_required",
                                primary_oms_id: 9999,
        } }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: { primary_oms: ["doesn't exist"] } }.deep_stringify_keys)
        end
      end

      response 400, "fails json validation on wrong parameter type", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
          name: "New offer",
          description: "asd",
          order_type: "order_required",
          parameters: [
            {
              "id": "0",
              "type": "aasd",
              "label": "constant_example",
              "description": "constant_hint",
              "value": "12",
              "value_type": "integer"
            },
          ]
        } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 400, "fails json validation on missing key", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
          name: "New offer",
          description: "asd",
          order_type: "order_required",
          parameters: [
            {
              "id": "0",
              "type": "attribute",
              "label": "constant_example",
              "description": "constant_hint",
              "value_type": "integer"
            }
          ]
        } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 400, "fails json validation on wrong select config values", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
          name: "New offer",
          description: "asd",
          order_type: "order_required",
          parameters: [
            {
              "id": "2",
              "type": "select",
              "label": "select_example",
              "description": "select_example",
              "config": {
                "values": [],
                "mode": "dropdown"
              },
              "value_type": "integer",
              "unit": "CPUs"
            },
          ]
        } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 400, "fails json validation on repeated parameters", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
          name: "New offer",
          description: "asd",
          order_type: "order_required",
          parameters: [
            {
              "id": "0",
              "type": "attribute",
              "label": "constant_example",
              "description": "constant_hint",
              "value": "12",
              "value_type": "integer",
            },
            {
              "id": "0",
              "type": "attribute",
              "label": "constant_example",
              "description": "constant_hint",
              "value": "12",
              "value_type": "integer",
            },
          ]
        } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 400, "fails model validation on wrong input type", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:resource_id) { service.slug }
        let(:offer_payload) { {
          name: "New offer",
          description: "asd",
          order_type: "order_required",
          parameters: [
            {
              "id": "0",
              "type": "attribute",
              "label": "constant_example",
              "description": "constant_hint",
              "value": "asd",
              "value_type": "integer",
            }
          ]
        } }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]["parameters"][0]).to eq("is invalid")
        end
      end

      response 400, "doesn't allow to create an offer with draft status", document: false do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]))}
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                order_type: "order_required",
                                status: "draft" } }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:resource_id) { 9999 }
        let(:offer_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service) }
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                order_type: "order_required" } }
        let(:resource_id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data["error"]).to eq("You are not authorized to perform this action.")
          expect(service.offers.length).to eq(0)
        end
      end

      response 404, "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:resource_id) { "definitely-doesnt-exist" }
        let(:offer_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end

      # TODO: default offer behaviour validation
    end
  end

  path "/api/v1/resources/{resource_id}/offers/{id}" do
    get "retrieves an offer for an administered resource" do
      tags "Offers"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
      parameter name: :id, in: :path, type: :string, description: "Offer identifier"

      response 200, "offer found" do
        schema "$ref" => "offer/offer_read.json"

        let(:offer) { build(:offer_with_all_parameters) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer]) }
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(offer.iid)
          expect(data["name"]).to eq(offer.name)
          expect(data["description"]).to eq(offer.description)
          expect(data["parameters"].length).to eq(offer.parameters.length)
          expect(data["parameters"][0]["type"]).to eq(offer.parameters.first.type)
          expect(data["parameters"][-1]["type"]).to eq(offer.parameters.last.type)
        end
      end

      response 200, "retrieves an offer without parameters", document: false do
        schema "$ref" => "offer/offer_read.json"

        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer]) }
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["id"]).to eq(offer.iid)
          expect(data["name"]).to eq(offer.name)
          expect(data["description"]).to eq(offer.description)
          expect(data["parameters"]).to match_array([])
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"

        let(:draft_offer) { build(:offer, status: "draft") }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [draft_offer]) }
        let(:resource_id) { service.slug }
        let(:id) { draft_offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You are not authorized to perform this action.")
        end
      end

      response 404, "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end

      response 404, "offer not found" do
        schema "$ref" => "error.json"

        let(:offer) { build(:offer_with_all_parameters) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer]) }
        let(:resource_id) { service.slug }
        let(:id) { "doesnt-exist" }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Offer not found.")
        end
      end
    end

    patch "updates an offer for an administered resource" do
      tags "Offers"
      produces "application/json"
      consumes "application/json"
      security [ authentication_token: [] ]
      parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
      parameter name: :id, in: :path, type: :string, description: "Offer identifier"
      parameter name: :offer_payload, in: :body, schema: { "$ref" => "offer/offer_update.json" }

      response 200, "offer updated" do
        schema "$ref" => "offer/offer_read.json"

        let(:previous_oms) { create(:oms, type: :global) }
        let(:oms) { create(:oms, type: :global, custom_params: { "a": { mandatory: true, default: "qwe" } }) }
        let(:offer) { build(:offer, primary_oms: previous_oms) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer])}
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                primary_oms_id: oms.id,
                                oms_params: { a: "b" }
        } }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer_payload[:name])
          expect(service.offers.first.description).to eq(offer_payload[:description])
          expect(service.offers.first.parameters.size).to eq(offer.parameters.size)
          expect(service.offers.first.order_url).to eq(offer.order_url)
          expect(service.offers.first.primary_oms).to eq(oms)
          expect(service.offers.first.oms_params).to eq({ a: "b" }.deep_stringify_keys)
        end
      end

      response 200, "deletes offer parameters", document: false do
        schema "$ref" => "offer/offer_read.json"

        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer])}
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { {
          parameters: []
        } }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer.name)
          expect(service.offers.first.description).to eq(offer.description)
          expect(service.offers.first.order_type).to eq(offer.order_type)
          expect(service.offers.first.parameters.size).to eq(offer_payload[:parameters].size)
          expect(service.offers.first.order_url).to eq(offer.order_url)
        end
      end

      response 200, "updates an offers parameters", document: false do
        # TODO: For now - parameters are updated as a whole - can't update individual parameter with some id
        schema "$ref" => "offer/offer_read.json"

        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer])}
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { {
          parameters: [
            {
              "id": "0",
              "type": "attribute",
              "label": "constant_example",
              "description": "constant_hint",
              "value": "12",
              "value_type": "integer",
            },
          ]
        } }

        run_test! do |response|
          data = JSON.parse(response.body)
          service.reload

          expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
          expect(service.offers.length).to eq(1)
          expect(service.offers.first.name).to eq(offer.name)
          expect(service.offers.first.description).to eq(offer.description)
          expect(service.offers.first.order_type).to eq(offer.order_type)
          expect(service.offers.first.parameters.size).to eq(offer_payload[:parameters].size)
          expect(service.offers.first.order_url).to eq(offer.order_url)
        end
      end

      response 400, "primary_oms model validation failed", document: false do
        schema "$ref" => "error.json"
        let(:oms) { create(:oms, type: :global, custom_params: { "a": { mandatory: true, default: "qwe" } }) }
        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer])}
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { { name: "New offer",
                                description: "sample description",
                                primary_oms_id: oms.id
        } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: { "oms_params": ["can't be blank"] } }.deep_stringify_keys)
        end
      end

      response 400, "doesnt allow to update status", document: false  do
        schema "$ref" => "error.json"

        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer])}
        let(:resource_id) { service.slug }
        let(:id) { offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { { status: "draft" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("The property '#/' of type object did not match all of the required schemas")

          expect(service.offers.first.status).to eq("published")
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }
        let(:offer_payload) { {} }


        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"

        let(:draft_offer) { build(:offer, status: "draft") }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [draft_offer])}
        let(:resource_id) { service.slug }
        let(:id) { draft_offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { { name: "New offer",
                                description: "sample description" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You are not authorized to perform this action.")
        end
      end

      response 404, "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }
        let(:offer_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end

      response 404, "offer not found" do
        schema "$ref" => "error.json"

        let(:offer) { build(:offer_with_all_parameters) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer]) }
        let(:resource_id) { service.slug }
        let(:id) { "doesnt-exist" }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Offer not found.")
        end
      end

      # TODO: default offer behaviour validation
    end

    delete "deletes an offer for an administered resource" do
      tags "Offers"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
      parameter name: :id, in: :path, type: :string, description: "Offer identifier"

      response 200, "offer deleted" do
        let(:offer1) { build(:offer) }
        let(:offer2) { build(:offer) }
        let(:offer3) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer1, offer2, offer3]) }
        let(:resource_id) { service.slug }
        let(:id) { offer2.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          service.reload

          expect(service.offers.count).to eq(2)
          expect(service.offers.first.name).to eq(offer1.name)
          expect(service.offers.second.name).to eq(offer3.name)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "not authorized" do
        schema "$ref" => "error.json"

        let(:draft_offer) { build(:offer, status: "draft") }
        let(:offer) { build(:offer) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer, draft_offer])}
        let(:resource_id) { service.slug }
        let(:id) { draft_offer.iid }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:offer_payload) { { name: "New offer",
                                description: "sample description" } }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You are not authorized to perform this action.")
        end
      end

      response 404, "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:resource_id) { 9999 }
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end

      response 404, "offer not found" do
        schema "$ref" => "error.json"

        let(:offer) { build(:offer_with_all_parameters) }
        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator]),
                                offers: [offer]) }
        let(:resource_id) { service.slug }
        let(:id) { "doesnt-exist" }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Offer not found.")
        end
      end

      # TODO: default offer behaviour validation
    end
  end
end
