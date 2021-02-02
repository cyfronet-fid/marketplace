# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe "Services API", swagger_doc: "v1/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/services" do
    get "lists services managed by user" do
      tags "Services"
      produces "application/json"
      security [ authentication_token: [] ]

      response "200", "return services managed by user" do
        schema type: :array,
               items: { "$ref" => "service.json" }

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:provider) { create(:provider, data_administrators: [data_administrator]) }
        let!(:service1) { create(:service, resource_organisation: provider) }
        let!(:service2) { create(:service, resource_organisation: provider) }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(2)
          expect(data[0]).to eq(JSON.parse(ServiceSerializer.new(service1).to_json))
          expect(data[1]).to eq(JSON.parse(ServiceSerializer.new(service2).to_json))
        end
      end

      response "200", "return empty list if user doesn't manage any services", document: false do
        schema type: :array,
               items: { "$ref" => "service.json" }

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }

        run_test! do |response|
          services = JSON.parse(response.body)
          expect(services.length).to eq(0)
        end
      end

      response "401", "denies entry for unknown token" do
        schema "$ref" => "error.json"

        let(:"X-User-Token") { "wrong-token" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("You need to sign in or sign up before continuing.")
        end
      end

      response "403", "denies entry non data administrator" do
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

  path "/api/v1/services/{id}" do
    get "retrieves a managed service" do
      tags "Services"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :id, in: :path, type: :string

      response "200", "lists a managed service" do
        schema "$ref" => "service.json"

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

      response "200", "lists a service with an eid", document: false do
        # TODO
      end

      response "403", "doesn't show unmanaged service" do
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

      response "404", "returns not found for nonexistent service id" do
        schema "$ref" => "error.json"

        let(:data_admin_user) { create(:user) }
        let!(:data_administrator) { create(:data_administrator, email: data_admin_user.email) }
        let(:"X-User-Token") { data_admin_user.authentication_token }
        let(:id) { "definitely-doesnt-exist" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["error"]).to eq("Service #{id} not found")
        end
      end
    end
  end
end
