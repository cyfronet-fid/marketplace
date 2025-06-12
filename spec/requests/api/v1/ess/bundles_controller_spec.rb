# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::BundlesController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/bundles" do
    get "lists published bundles" do
      tags "bundles"
      produces "application/json"
      security [authentication_token: []]

      response 200, "bundle found" do
        schema "$ref" => "ess/bundle/bundle_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:bundles) { create_list(:bundle, 2) }
        let!(:second_bundle) { create(:bundle, service_id: bundles.first.service_id) }
        let!(:draft) { create(:bundle, service_id: bundles.second.service_id, status: :draft) }
        let!(:deleted) { create(:bundle, status: :deleted) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          expected = bundles << second_bundle
          data = JSON.parse(response.body)

          expect(data.length).to eq(expected.size)
          expect(data).to match_array(expected&.map { |s| Ess::BundleSerializer.new(s).as_json.deep_stringify_keys })
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:bundles) { create_list(:bundle, 3) }
        let!(:second_bundle) { create(:bundle, service_id: bundles.first.service_id) }
        let!(:draft) { create(:bundle, service_id: bundles.second.service_id, status: :draft) }
        let!(:deleted) { create(:bundle, status: :deleted) }

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

  path "/api/v1/ess/bundles/{bundle_id}" do
    parameter name: :bundle_id, in: :path, type: :string, description: "bundle identifier id"

    get "retrieves a bundle by id" do
      tags "bundles"
      produces "application/json"
      security [authentication_token: []]

      response 200, "bundle found by id" do
        schema "$ref" => "ess/bundle/bundle_read.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:bundle) { create(:bundle) }

        let(:bundle_id) { bundle.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)

          expect(data).to eq(Ess::BundleSerializer.new(bundle).as_json.deep_stringify_keys)
        end
      end

      response 404, "draft bundle not found by id" do
        schema "$ref" => "error.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:bundle) { create(:bundle, status: :draft) }

        let(:bundle_id) { bundle.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Resource not found" }.deep_stringify_keys)
        end
      end

      response 403, "bundle not found by unpermitted user" do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:bundle) { create(:bundle, status: :draft) }

        let(:bundle_id) { bundle.id }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:bundle_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
