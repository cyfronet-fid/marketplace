# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Resources::OffersController, swagger_doc: "v1/offering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  before(:each) { create(:default_oms) }

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end
  context "predefined variables" do
    let(:service_category) { create(:service_category_other) }

    path "/api/v1/resources/{resource_id}/offers" do
      get "lists offers for an administered resource" do
        tags "Offers"
        produces "application/json"
        security [authentication_token: []]
        parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"

        response 200, "offers found" do
          schema "$ref" => "offer/offer_index.json"

          let(:published_offer1) { build(:offer_with_all_parameters, offer_category: service_category) }
          let(:published_offer2) { build(:offer_with_all_parameters, offer_category: service_category) }
          let(:draft_offer) { build(:offer, status: "draft", offer_category: service_category) }
          let(:bundled_offer1) { build(:offer, offer_category: service_category) }
          let(:bundled_offer2) { build(:offer, offer_category: service_category) }
          let(:bundle_offer) { build(:offer, offer_category: service_category) }
          let(:bundle) { build(:bundle, main_offer: bundle_offer, offers: [bundled_offer1, bundled_offer2]) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [published_offer1, published_offer2, draft_offer, bundle_offer],
              bundles: [bundle]
            )
          end
          let(:resource_id) { service.slug }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["offers"].length).to eq(3)

            expect(data["offers"][0]["id"]).to eq(published_offer1.iid)
            expect(data["offers"][0]["name"]).to eq(published_offer1.name)
            expect(data["offers"][0]["description"]).to eq(published_offer1.description)
            expect(data["offers"][0]["internal"]).to eq(true)
            expect(data["offers"][0]["primary_oms_id"]).to eq(OMS.find_by(default: true).id)
            expect(data["offers"][0]["parameters"].length).to eq(published_offer1.parameters.length)
            expect(data["offers"][0]["parameters"][0]["type"]).to eq(published_offer1.parameters.first.type)
            expect(data["offers"][0]["parameters"][-1]["type"]).to eq(published_offer1.parameters.last.type)

            expect(data["offers"][1]["id"]).to eq(published_offer2.iid)
            expect(data["offers"][1]["name"]).to eq(published_offer2.name)
            expect(data["offers"][1]["description"]).to eq(published_offer2.description)
            expect(data["offers"][1]["internal"]).to eq(true)
            expect(data["offers"][1]["primary_oms_id"]).to eq(OMS.find_by(default: true).id)
            expect(data["offers"][1]["parameters"].length).to eq(published_offer2.parameters.length)
            expect(data["offers"][1]["parameters"][0]["type"]).to eq(published_offer2.parameters.first.type)
            expect(data["offers"][1]["parameters"][-1]["type"]).to eq(published_offer2.parameters.last.type)

            expect(data["offers"][2]["id"]).to eq(bundle_offer.iid)
            expect(data["offers"][2]["name"]).to eq(bundle_offer.name)
            expect(data["offers"][2]["description"]).to eq(bundle_offer.description)
            expect(data["offers"][2]["internal"]).to eq(true)
            expect(data["offers"][2]["primary_oms_id"]).to eq(OMS.find_by(default: true).id)
            expect(data["offers"][2]["parameters"].length).to eq(0)
            expect(data["offers"][2]["bundled_offers"]).to eq(
              [{ "#{bundle.id}" => [bundled_offer1.slug_iid, bundled_offer2.slug_iid] }]
            )
          end
        end

        response 200, "offers found but were empty", document: false do
          schema "$ref" => "offer/offer_index.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end

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
        security [authentication_token: []]
        parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
        parameter name: :offer_payload, in: :body, schema: { "$ref" => "offer/offer_write.json" }

        response 201, "offer created" do
          schema "$ref" => "offer/offer_read.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:offer) { build(:offer_with_all_parameters, offer_category: service_category) }
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
            expect(service.offers.first.internal).to eq(offer.internal)
            expect(service.offers.first.primary_oms).to eq(OMS.find_by(default: true))
          end
        end

        response 201, "open_access offer created", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "order_required",
              offer_category: service_category.eid
            }
          end
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
            expect(service.offers.first.internal).to eq(false)
            expect(service.offers.first.primary_oms).to be_nil
            expect(service.offers.first.oms_params).to be_nil
          end
        end

        response 201, "offer with oms_params created", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:oms) { create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "qwe" } }) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }

          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "order_required",
              internal: true,
              offer_category: service_category.eid,
              primary_oms_id: oms.id,
              oms_params: {
                a: "asd"
              }
            }
          end
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
            expect(service.offers.first.internal).to eq(true)
            expect(service.offers.first.primary_oms).to eq(oms)
            expect(service.offers.first.oms_params).to eq({ a: "asd" }.deep_stringify_keys)
          end
        end

        response 201, "ignores internal, primary_oms and oms_params if open_access", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              order_type: "open_access",
              resource_organisation: create(:provider, data_administrators: [data_administrator])
            )
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "open_access",
              offer_category: service_category.eid,
              internal: true,
              primary_oms_id: 1,
              oms_params: {
                a: "b"
              }
            }
          end
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
            expect(service.offers.first.internal).to eq(false)
            expect(service.offers.first.primary_oms).to be_nil
            expect(service.offers.first.oms_params).to be_nil
          end
        end

        response 201, "ignores primary_oms and oms_params if not internal", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              order_type: "open_access",
              resource_organisation: create(:provider, data_administrators: [data_administrator])
            )
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "open_access",
              offer_category: service_category.eid,
              internal: false,
              primary_oms_id: 1,
              oms_params: {
                a: "b"
              }
            }
          end
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
            expect(service.offers.first.internal).to eq(false)
            expect(service.offers.first.primary_oms).to be_nil
            expect(service.offers.first.oms_params).to be_nil
          end
        end

        response 400, "bad request" do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) { { name: "New offer", description: "asd", order_type: "lol" } }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq(
              "The property '#/order_type' value \"lol\" did not match one of the following " +
                "values: open_access, fully_open_access, order_required, other"
            )
          end
        end

        response 400, "fails model validation on non-existent primary_oms_id", document: false do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "order_required",
              offer_category: service_category.eid,
              internal: true,
              primary_oms_id: 9999
            }
          end
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
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "asd",
              order_type: "order_required",
              offer_category: service_category.eid,
              parameters: [
                {
                  id: "0",
                  type: "aasd",
                  label: "constant_example",
                  description: "constant_hint",
                  value: "12",
                  value_type: "integer"
                }
              ]
            }
          end
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq(
              "The property '#/parameters/0' of type object did not match any of the required schemas"
            )
          end
        end

        response 400, "fails json validation on missing key", document: false do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "asd",
              order_type: "order_required",
              offer_category: service_category.eid,
              parameters: [
                {
                  id: "0",
                  type: "attribute",
                  label: "constant_example",
                  description: "constant_hint",
                  value_type: "integer"
                }
              ]
            }
          end
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq(
              "The property '#/parameters/0' of type object did not match any of the required schemas"
            )
          end
        end

        response 400, "fails json validation on wrong select config values", document: false do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "asd",
              order_type: "order_required",
              offer_category: service_category.eid,
              parameters: [
                {
                  id: "2",
                  type: "select",
                  label: "select_example",
                  description: "select_example",
                  config: {
                    values: [],
                    mode: "dropdown"
                  },
                  value_type: "integer",
                  unit: "CPUs"
                }
              ]
            }
          end
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq(
              "The property '#/parameters/0' of type object did not match any of the required schemas"
            )
          end
        end

        response 400, "fails json validation on repeated parameters", document: false do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "asd",
              order_type: "order_required",
              offer_category: service_category.eid,
              parameters: [
                {
                  id: "0",
                  type: "attribute",
                  label: "constant_example",
                  description: "constant_hint",
                  value: "12",
                  value_type: "integer"
                },
                {
                  id: "0",
                  type: "attribute",
                  label: "constant_example",
                  description: "constant_hint",
                  value: "12",
                  value_type: "integer"
                }
              ]
            }
          end
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("The property '#/parameters' contained duplicated array values")
          end
        end

        response 400, "fails model validation on wrong input type", document: false do
          schema "$ref" => "error.json"

          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:resource_id) { service.slug }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "asd",
              order_type: "order_required",
              offer_category: service_category.eid,
              parameters: [
                {
                  id: "0",
                  type: "attribute",
                  label: "constant_example",
                  description: "constant_hint",
                  value: "asd",
                  value_type: "integer"
                }
              ]
            }
          end
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
          let!(:service) do
            create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
          end
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              offer_category: service_category.eid,
              order_type: "order_required",
              status: "draft"
            }
          end
          let(:resource_id) { service.slug }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("The property '#/' of type object matched the disallowed schema")
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
          let(:offer_payload) { { name: "New offer", description: "sample description", order_type: "order_required" } }
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
        security [authentication_token: []]
        parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
        parameter name: :id, in: :path, type: :string, description: "Offer identifier"

        response 200, "offer found" do
          schema "$ref" => "offer/offer_read.json"

          let(:offer) { build(:offer_with_all_parameters, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
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
            expect(data["primary_oms_id"]).to eq(OMS.find_by(default: true).id)
            expect(data["oms_params"]).to be_nil
          end
        end

        response 200, "retrieves an offer without parameters", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:offer) { build(:offer, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["id"]).to eq(offer.iid)
            expect(data["name"]).to eq(offer.name)
            expect(data["description"]).to eq(offer.description)
            expect(data["parameters"]).to match_array([])
            expect(data["primary_oms_id"]).to eq(OMS.find_by(default: true).id)
            expect(data["oms_params"]).to be_nil
          end
        end

        response 200, "doesn't show primary_oms_id and oms_params if not internal", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:offer) { build(:offer, internal: false, order_type: :order_required, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["id"]).to eq(offer.iid)
            expect(data["name"]).to eq(offer.name)
            expect(data["description"]).to eq(offer.description)
            expect(data["parameters"]).to match_array([])
            expect(data["primary_oms_id"]).to be_nil
            expect(data["oms_params"]).to be_nil
            expect(data["internal"]).to eq(false)
          end
        end

        response 200, "doesn't show internal, oms_params and primary_oms_id if not order_required", document: false do
          schema "$ref" => "offer/offer_read.json"

          let(:offer) { build(:offer, order_type: :open_access, internal: false, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :open_access_service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["id"]).to eq(offer.iid)
            expect(data["name"]).to eq(offer.name)
            expect(data["description"]).to eq(offer.description)
            expect(data["parameters"]).to match_array([])
            expect(data["primary_oms_id"]).to be_nil
            expect(data["oms_params"]).to be_nil
            expect(data["internal"]).to be_nil
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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [draft_offer]
            )
          end
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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { "doesnt-exist" }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("Offer not found")
          end
        end
      end

      patch "updates an offer for an administered resource" do
        tags "Offers"
        produces "application/json"
        consumes "application/json"
        security [authentication_token: []]
        parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
        parameter name: :id, in: :path, type: :string, description: "Offer identifier"
        parameter name: :offer_payload, in: :body, schema: { "$ref" => "offer/offer_update.json" }

        response 200, "offer updated" do
          schema "$ref" => "offer/offer_read.json"

          let(:previous_oms) { create(:oms, type: :global) }
          let(:oms) { create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "qwe" } }) }
          let(:offer) { build(:offer, primary_oms: previous_oms, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              offer_category: service_category.eid,
              primary_oms_id: oms.id,
              oms_params: {
                a: "b"
              }
            }
          end

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

          let(:offer) { build(:offer, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { { parameters: [] } }

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

          let(:offer) { build(:offer, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) do
            {
              parameters: [
                {
                  id: "0",
                  type: "attribute",
                  label: "constant_example",
                  description: "constant_hint",
                  value: "12",
                  value_type: "integer"
                }
              ]
            }
          end

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

        response 200, "doesn't update primary_oms and oms_params if not internal" do
          schema "$ref" => "offer/offer_read.json"

          let(:previous_oms) { create(:oms, type: :global) }
          let(:oms) { create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "qwe" } }) }
          let(:offer) { build(:offer, primary_oms: previous_oms, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              internal: false,
              primary_oms_id: oms.id,
              oms_params: {
                a: "b"
              }
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            service.reload

            expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
            expect(service.offers.length).to eq(1)
            expect(service.offers.first.name).to eq(offer_payload[:name])
            expect(service.offers.first.description).to eq(offer_payload[:description])
            expect(service.offers.first.parameters.size).to eq(offer.parameters.size)
            expect(service.offers.first.order_url).to eq(offer.order_url)
            expect(service.offers.first.primary_oms).to be_nil
            expect(service.offers.first.oms_params).to be_nil
          end
        end

        response 200, "doesn't update primary_oms and oms_params and internal if not order_required" do
          schema "$ref" => "offer/offer_read.json"

          let(:previous_oms) { create(:oms, type: :global) }
          let(:oms) { create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "qwe" } }) }
          let(:offer) { build(:open_access_offer, primary_oms: previous_oms, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :open_access_service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) do
            {
              name: "New offer",
              description: "sample description",
              order_type: "open_access",
              internal: true,
              primary_oms_id: oms.id,
              oms_params: {
                a: "b"
              }
            }
          end

          run_test! do |response|
            data = JSON.parse(response.body)
            service.reload

            expect(data).to eq(JSON.parse(Api::V1::OfferSerializer.new(service.offers.first).to_json))
            expect(service.offers.length).to eq(1)
            expect(service.offers.first.name).to eq(offer_payload[:name])
            expect(service.offers.first.description).to eq(offer_payload[:description])
            expect(service.offers.first.parameters.size).to eq(offer.parameters.size)
            expect(service.offers.first.order_url).to eq(offer.order_url)
            expect(service.offers.first.order_type).to eq("open_access")
            expect(service.offers.first.internal).to be_falsey
            expect(service.offers.first.primary_oms).to be_nil
            expect(service.offers.first.oms_params).to be_nil
          end
        end

        response 400, "primary_oms model validation failed", document: false do
          schema "$ref" => "error.json"
          let(:oms) { create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "qwe" } }) }
          let(:offer) { build(:offer, offer_category: service_category) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { { name: "New offer", description: "sample description", primary_oms_id: oms.id } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to eq({ error: { oms_params: ["can't be blank"] } }.deep_stringify_keys)
          end
        end

        response 400, "doesnt allow to update status", document: false do
          schema "$ref" => "error.json"

          let(:offer) { build(:offer) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { { status: "draft" } }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("The property '#/' of type object matched the disallowed schema")

            expect(service.offers.first.status).to eq("published")
          end
        end

        response 400, "fails model validation on incorrect bundled offer id", document: false do
          schema "$ref" => "error.json"

          let(:offer) { build(:offer) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:offer_payload) { { bundled_offers: ["not-a-valid-id"] } }
          let(:resource_id) { service.slug }
          let(:id) { offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq(
              "The property '#/bundled_offers/0' of type string did not match any of the required schemas"
            )
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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [draft_offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { draft_offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { { name: "New offer", description: "sample description" } }

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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { "doesnt-exist" }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { {} }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("Offer not found")
          end
        end

        # TODO: default offer behaviour validation
      end

      delete "deletes an offer for an administered resource" do
        tags "Offers"
        produces "application/json"
        security [authentication_token: []]
        parameter name: :resource_id, in: :path, type: :string, description: "Resource identifier (id or eid)"
        parameter name: :id, in: :path, type: :string, description: "Offer identifier"

        response 200, "offer deleted" do
          let(:offer1) { build(:offer) }
          let(:offer2) { build(:offer) }
          let(:offer3) { build(:offer) }
          let(:data_admin_user) { create(:user) }
          let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer1, offer2, offer3]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { offer2.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |_response|
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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer, draft_offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { draft_offer.iid }
          let(:"X-User-Token") { data_admin_user.authentication_token }
          let(:offer_payload) { { name: "New offer", description: "sample description" } }

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
          let!(:service) do
            create(
              :service,
              resource_organisation: create(:provider, data_administrators: [data_administrator]),
              offers: [offer]
            )
          end
          let(:resource_id) { service.slug }
          let(:id) { "doesnt-exist" }
          let(:"X-User-Token") { data_admin_user.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data["error"]).to eq("Offer not found")
          end
        end

        # TODO: default offer behaviour validation
      end
    end
  end
end
