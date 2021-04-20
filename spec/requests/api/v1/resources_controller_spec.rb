# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe "Resources API", swagger_doc: "v1/offering_swagger.json" do
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
      security [ authentication_token: [] ]

      response "200", "resources found" do
        schema "$ref" => "service/service_index.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:provider) { create(:provider, data_administrators: [data_administrator]) }
        let!(:service1) { create(:service, resource_organisation: provider) }
        let!(:service2) { create(:service, resource_organisation: provider) }
        let!(:deleted_service) { create(:service, resource_organisation: provider, status: :deleted) }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(2)
          expect(data[0]).to eq(JSON.parse(ServiceSerializer.new(service1).to_json))
          expect(data[1]).to eq(JSON.parse(ServiceSerializer.new(service2).to_json))
        end
      end

      response "200", "resources found but were an empty list", document: false do
        schema "$ref" => "service/service_index.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(0)
        end
      end

      response "401", "unauthorized" do
        schema "$ref" => "error.json"

        let(:"X-User-Token") { "wrong-token" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You need to sign in or sign up before continuing.")
        end
      end

      response "403", "forbidden" do
        schema "$ref" => "error.json"

        let(:regular_user) { create(:user) }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You are not authorized to perform this action.")
        end
      end
    end
  end

  path "/api/v1/resources/{id}" do
    get "retrieves an administered resource" do
      tags "Resources"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :id, in: :path, type: :string, description: "Resource identifier (id or eid)"

      response "200", "resource found" do
        schema "$ref" => "service/service_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator])) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { service.slug }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(JSON.parse(ServiceSerializer.new(service).to_json))
        end
      end

      response "200", "resource found with an eid", document: false do
        schema "$ref" => "service/service_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                pid: "qwe.asd",
                                resource_organisation: create(:provider, data_administrators: [data_administrator])) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { service.pid }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(JSON.parse(ServiceSerializer.new(service).to_json))
        end
      end

      response 200, "resource along with its available oms found", document: false do
        schema "$ref" => "service/service_read.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_admin) { create(:data_administrator, email: data_admin_user.email) }

        let(:provider1) { create(:provider, data_administrators: [data_admin]) }
        let(:provider2) { create(:provider) }
        let(:service) { create(:service, providers: [provider1, provider2], resource_organisation: provider1) }

        let!(:default_oms) { create(:oms, type: :global, default: true) }
        let!(:provider_group_oms) { create(:oms, type: :provider_group, providers: [provider1, provider2]) }
        let!(:resource_oms) { create(:oms, service: service, type: :resource_dedicated) }
        let!(:other_resource_oms) { create(:oms, type: :resource_dedicated, service: build(:service)) }

        let(:id) { service.slug }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["available_oms"])
            .to eq([default_oms, resource_oms, provider_group_oms]
                     .map { |oms| OrderingApi::V1::OmsSerializer.new(oms).as_json.deep_stringify_keys })
        end
      end

      response "403", "forbidden" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let!(:service) { create(:service,
                                resource_organisation: create(:provider, data_administrators: [data_administrator])) }

        let(:diff_data_admin_user) { create(:user) }
        let!(:diff_data_administrator) { create(:data_administrator, email: diff_data_admin_user.email) }

        let(:"X-User-Token") { diff_data_admin_user.authentication_token }
        let(:id) { service.slug }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You are not authorized to perform this action.")
        end
      end

      response "404", "resource not found" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { "definitely-doesnt-exist" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Resource #{id} not found")
        end
      end
    end
  end
end
