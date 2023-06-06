# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::ResourcesController, swagger_doc: "v1/offering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/resources" do
    get "lists resources administered by user" do
      tags "Resources"
      produces "application/json"
      security [authentication_token: []]

      response 200, "resources found" do
        schema "$ref" => "resource/resource_index.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:provider) { create(:provider, data_administrators: [data_administrator]) }
        let!(:service1) { create(:service, resource_organisation: provider) }
        let!(:service2) { create(:service, resource_organisation: provider) }
        let!(:deleted_service) { create(:service, resource_organisation: provider, status: :deleted) }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["resources"].length).to eq(2)
          expect(data["resources"][0]).to eq(JSON.parse(Api::V1::ServiceSerializer.new(service1).to_json))
          expect(data["resources"][1]).to eq(JSON.parse(Api::V1::ServiceSerializer.new(service2).to_json))
        end
      end

      response 200, "resources found but were empty", document: false do
        schema "$ref" => "resource/resource_index.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:other_data_admin_user) { create(:user) }
        let!(:other_data_administrator) { create(:data_administrator, email: other_data_admin_user.email) }
        let(:provider) { create(:provider, data_administrators: [data_administrator]) }
        let!(:service) { create(:service, resource_organisation: provider) }

        let(:"X-User-Token") { other_data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["resources"].length).to eq(0)
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

  path "/api/v1/resources/{id}" do
    get "retrieves an administered resource" do
      tags "Resources"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :id, in: :path, type: :string, description: "Resource identifier (id or eid)"

      response 200, "resource found" do
        schema "$ref" => "resource/resource_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) do
          create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
        end
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { service.slug }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(JSON.parse(Api::V1::ServiceSerializer.new(service).to_json))
        end
      end

      response 200, "resource found with an eid", document: false do
        schema "$ref" => "resource/resource_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) do
          create(
            :service,
            pid: "qwe.asd",
            resource_organisation: create(:provider, data_administrators: [data_administrator])
          )
        end
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { service.pid }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(JSON.parse(Api::V1::ServiceSerializer.new(service).to_json))
        end
      end

      response 200, "resource along with its available oms found", document: false do
        schema "$ref" => "resource/resource_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_admin) { create(:data_administrator, email: data_admin_user.email) }

        let(:provider1) { create(:provider, data_administrators: [data_admin]) }
        let(:provider2) { create(:provider) }
        let(:service) { create(:service, resource_organisation: provider1) }

        let!(:default_oms) do
          create(
            :default_oms,
            type: :global,
            custom_params: {
              param: {
                mandatory: true,
                default: "some_default"
              },
              other_param: {
                mandatory: false
              }
            }
          )
        end
        let!(:provider_group_oms) { create(:oms, type: :provider_group, providers: [provider1, provider2]) }
        let!(:provider2_group_oms) { create(:oms, type: :provider_group, providers: [provider2]) }
        let!(:resource_oms) { create(:oms, service: service, type: :resource_dedicated) }
        let!(:other_resource_oms) { create(:oms, type: :resource_dedicated, service: build(:service)) }

        let(:id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["available_omses"]).to eq(
            [
              {
                id: default_oms.id,
                name: default_oms.name,
                type: default_oms.type,
                custom_params: {
                  param: {
                    mandatory: true
                  },
                  other_param: {
                    mandatory: false
                  }
                }
              },
              { id: resource_oms.id, name: resource_oms.name, type: resource_oms.type },
              { id: provider_group_oms.id, name: provider_group_oms.name, type: provider_group_oms.type }
            ].map(&:deep_stringify_keys)
          )
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) do
          create(:service, resource_organisation: create(:provider, data_administrators: [data_administrator]))
        end

        let(:diff_data_admin_user) { create(:user) }
        let!(:diff_data_administrator) { create(:data_administrator, email: diff_data_admin_user.email) }

        let(:"X-User-Token") { diff_data_admin_user.authentication_token }
        let(:id) { service.slug }

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
        let(:id) { "definitely-doesnt-exist" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource not found")
        end
      end
    end
  end
end
