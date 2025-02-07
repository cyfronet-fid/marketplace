# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::CataloguesController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/catalogues" do
    get "lists catalogues" do
      tags "catalogues"
      produces "application/json"
      security [authentication_token: []]

      response 200, "catalogues found" do
        schema "$ref" => "ess/catalogue/catalogue_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:catalogues) { create_list(:catalogue, 2) }
        let!(:draft) { create(:catalogue, status: :draft) }
        let!(:deleted) { create(:catalogue, status: :deleted) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length).to eq(2)
          expect(data).to eq(catalogues&.map { |s| Ess::CatalogueSerializer.new(s).as_json.deep_stringify_keys })
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let(:regular_user) { create(:user) }
        let(:manager) { create(:user, roles: [:coordinator]) }
        let(:catalogues) { create_list(:catalogue, 3) }

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

  path "/api/v1/ess/catalogues/{catalogue_id}" do
    parameter name: :catalogue_id, in: :path, type: :string, description: "Catalogue identifier (id or pid)"

    get "retrieves a catalogue by id" do
      tags "catalogues"
      produces "application/json"
      security [authentication_token: []]

      %i[id pid].each do |id_form|
        response 200, "catalogue found by #{id_form}" do
          schema "$ref" => "ess/catalogue/catalogue_read.json"
          let!(:manager) { create(:user, roles: [:coordinator]) }
          let!(:catalogue) { create(:catalogue) }

          let(:catalogue_id) { catalogue.send(id_form) }
          let(:"X-User-Token") { manager.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to eq(Ess::CatalogueSerializer.new(catalogue).as_json.deep_stringify_keys)
          end
        end
      end

      response 404, "draft catalogue not found by id" do
        schema "$ref" => "error.json"
        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:catalogue) { create(:catalogue, status: :draft) }

        let(:catalogue_id) { catalogue.id }
        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Resource not found" }.deep_stringify_keys)
        end
      end

      response 403, "catalogue not found by unpermitted user" do
        schema "$ref" => "error.json"
        let!(:regular_user) { create(:user) }
        let!(:catalogue) { create(:catalogue, status: :draft) }

        let(:catalogue_id) { catalogue.id }
        let(:"X-User-Token") { regular_user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:catalogue_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
