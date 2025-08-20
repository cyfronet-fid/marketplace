# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::DeployableServicesController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/deployable_services" do
    get "lists deployable services" do
      tags "deployable_services"
      produces "application/json"
      security [authentication_token: []]

      response 200, "deployable services found" do
        schema "$ref" => "ess/deployable_service/deployable_service_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:deployable_services) { create_list(:deployable_service, 3) }
        let!(:draft) { create(:deployable_service, status: :draft) }
        let!(:deleted) { create(:deployable_service, status: :deleted) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expected = deployable_services
          expect(data.length).to eq(expected.size)
          expect(data).to eq(
            expected&.map { |ds| Ess::DeployableServiceSerializer.new(ds).as_json.deep_stringify_keys }
          )
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let(:regular_user) { create(:user) }
        let(:manager) { create(:user, roles: [:coordinator]) }
        let(:deployable_services) { create_list(:deployable_service, 3) }

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

  path "/api/v1/ess/deployable_services/{deployable_service_id}" do
    parameter name: :deployable_service_id,
              in: :path,
              type: :string,
              description: "Deployable Service identifier (id or slug)"

    get "retrieves a deployable service by id" do
      tags "deployable_services"
      produces "application/json"
      security [authentication_token: []]

      %i[id pid slug].each do |id_form|
        response 200, "deployable service found by #{id_form}" do
          schema "$ref" => "ess/deployable_service/deployable_service_read.json"
          let!(:manager) { create(:user, roles: [:coordinator]) }
          let!(:deployable_service) { create(:deployable_service) }

          let(:deployable_service_id) { deployable_service.send(id_form) }
          let(:"X-User-Token") { manager.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to eq(Ess::DeployableServiceSerializer.new(deployable_service).as_json.deep_stringify_keys)
          end
        end
      end

      response 404, "draft deployable service not found by id" do
        schema "$ref" => "error.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:deployable_service) { create(:deployable_service, status: :draft) }

        let(:deployable_service_id) { deployable_service.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Resource not found" }.deep_stringify_keys)
        end
      end

      response 403, "deployable service not found by unpermitted user" do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:deployable_service) { create(:deployable_service, status: :draft) }

        let(:deployable_service_id) { deployable_service.id }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:deployable_service_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
