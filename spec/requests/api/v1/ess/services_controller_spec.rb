# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::ServicesController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/services" do
    get "lists services" do
      tags "services"
      produces "application/json"
      security [authentication_token: []]

      response 200, "services found" do
        schema "$ref" => "ess/service/service_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:services) { create_list(:service, 3) }
        let!(:draft) { create(:service, status: :draft) }
        let!(:deleted) { create(:service, status: :deleted) }
        let!(:datasource) { create(:datasource) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expected = services
          expect(data.length).to eq(expected.size)
          expect(data).to eq(expected&.map { |s| Ess::ServiceSerializer.new(s).as_json.deep_stringify_keys })
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let(:regular_user) { create(:user) }
        let(:manager) { create(:user, roles: [:coordinator]) }
        let(:services) { create_list(:service, 3) }

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

  path "/api/v1/ess/services/{service_id}" do
    parameter name: :service_id, in: :path, type: :string, description: "Service identifier (id or eid)"

    get "retrieves a service by id" do
      tags "services"
      produces "application/json"
      security [authentication_token: []]

      %i[id pid slug].each do |id_form|
        response 200, "service found by #{id_form}" do
          schema "$ref" => "ess/service/service_read.json"
          let!(:manager) { create(:user, roles: [:coordinator]) }
          let!(:service) { create(:service) }

          let(:service_id) { service.send(id_form) }
          let(:"X-User-Token") { manager.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to eq(Ess::ServiceSerializer.new(service).as_json.deep_stringify_keys)
          end
        end
      end

      response 404, "draft service not found by id" do
        schema "$ref" => "error.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:service) { create(:service, status: :draft) }

        let(:service_id) { service.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Resource not found" }.deep_stringify_keys)
        end
      end

      response 403, "service not found by unpermitted user" do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:service) { create(:service, status: :draft) }

        let(:service_id) { service.id }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:service_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
