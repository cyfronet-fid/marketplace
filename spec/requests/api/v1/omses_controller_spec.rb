# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::OMSesController, swagger_doc: "v1/ordering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms" do
    get "lists OMSes" do
      tags "OMS"
      produces "application/json"
      security [authentication_token: []]

      response 200, "OMSes found" do
        schema "$ref" => "oms/ordering/oms_index.json"
        let(:oms_admin) { create(:user) }
        let!(:oms) { create_list(:oms, 2, administrators: [oms_admin]) }

        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            { omses: oms.map { |oms| Api::V1::Ordering::OMSSerializer.new(oms).as_json } }.deep_stringify_keys
          )
        end
      end

      response 200, "user doesn't administrate any OMSes", document: false do
        schema "$ref" => "oms/ordering/oms_index.json"
        let(:regular_user) { create(:user) }
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ omses: [] }.deep_stringify_keys)
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

  path "/api/v1/oms/{oms_id}" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"

    get "retrieves an OMS" do
      tags "OMS"
      produces "application/json"
      security [authentication_token: []]

      response 200, "OMS found" do
        schema "$ref" => "oms/ordering/oms_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::Ordering::OMSSerializer.new(oms).as_json.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:oms_id) { 9999 }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end
    end
  end
end
