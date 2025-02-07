# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::Ess::DatasourcesController, swagger_doc: "v1/ess_swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/ess/datasources" do
    get "lists datasources" do
      tags "datasources"
      produces "application/json"
      security [authentication_token: []]

      response 200, "datasources found" do
        schema "$ref" => "ess/datasource/datasource_index.json"

        let!(:manager) { create(:user, roles: [:coordinator]) }
        let!(:datasources) { create_list(:datasource, 3) }
        let!(:draft) { create(:datasource, status: :draft) }
        let!(:deleted) { create(:datasource, status: :deleted) }
        let!(:service) { create(:service) }

        let(:"X-User-Token") { manager.authentication_token }

        run_test! do |response|
          expected = datasources
          data = JSON.parse(response.body)

          expect(data.length).to eq(expected.size)
          expect(data).to eq(expected&.map { |s| Ess::DatasourceSerializer.new(s).as_json.deep_stringify_keys })
        end
      end

      response 403, "user doesn't have manager role", document: false do
        schema "$ref" => "error.json"
        let(:regular_user) { create(:user) }
        let(:manager) { create(:user, roles: [:coordinator]) }
        let!(:datasources) { create_list(:datasource, 3) }

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

  path "/api/v1/ess/datasources/{datasource_id}" do
    parameter name: :datasource_id, in: :path, type: :string, description: "Datasource identifier (id or eid)"

    get "retrieves a datasource by id" do
      tags "datasources"
      produces "application/json"
      security [authentication_token: []]

      %i[id pid slug].each do |id_form|
        response 200, "datasource found by #{id_form}" do
          schema "$ref" => "ess/datasource/datasource_read.json"
          let!(:manager) { create(:user, roles: [:coordinator]) }
          let!(:datasource) { create(:datasource) }

          let(:datasource_id) { datasource.send(id_form) }
          let(:"X-User-Token") { manager.authentication_token }

          run_test! do |response|
            data = JSON.parse(response.body)
            expect(data).to eq(Ess::DatasourceSerializer.new(datasource).as_json.deep_stringify_keys)
          end
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "asdasdasd" }
        let(:datasource_id) { "test" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end
    end
  end
end
