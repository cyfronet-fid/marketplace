# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe "Ordering ProjectItems API", swagger_doc: "v1/ordering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/projects/{p_id}/project_items" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"
    parameter name: :p_id, in: :path, type: :string, description: "Project id"

    get "lists project items" do
      tags "Project items"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :from_id,
                in: :query,
                type: :integer,
                required: false,
                description: "List project items with project_item_id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false, description: "Number of returned elements"

      response 200, "project items found" do
        schema "$ref" => "project_item/project_item_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let!(:project_items) do
          [
            create(:project_item, offer: build(:offer, primary_oms: oms), project: project, iid: 1),
            create(
              :project_item,
              offer: build(:offer, primary_oms: oms),
              project: project,
              iid: 2,
              user_secrets: {
                key: "value"
              }
            ),
            create(:project_item, offer: build(:offer, primary_oms: other_oms), project: project, iid: 3),
            create(:project_item, offer: build(:offer, primary_oms: oms), project: project, iid: 4),
            create(:project_item, offer: build(:offer, primary_oms: oms), project: project, iid: 5)
          ]
        end

        let(:from_id) { 1 }
        let(:limit) { 2 }
        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            {
              project_items:
                project_items
                  .values_at(1, 3)
                  .map do |pi|
                    serialized = Api::V1::ProjectItemSerializer.new(pi).as_json
                    serialized[:user_secrets] = serialized[:user_secrets].transform_values { |_| "<OBFUSCATED>" }
                    serialized
                  end
            }.deep_stringify_keys
          )
        end
      end

      response 200, "project items found but were empty", document: false do
        schema "$ref" => "project_item/project_item_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ project_items: [] }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        let(:"X-User-Token") { "asdasdasd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized to access this OMS" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 1 }
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
        let(:p_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 9999 }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.deep_stringify_keys)
        end
      end
    end
  end

  path "/api/v1/oms/{oms_id}/projects/{p_id}/project_items/{pi_id}" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"
    parameter name: :p_id, in: :path, type: :string, description: "Project id"
    parameter name: :pi_id, in: :path, type: :string, description: "Project item id"

    get "retrieves a project item" do
      tags "Project items"
      produces "application/json"
      security [authentication_token: []]

      response 200, "project item found" do
        schema "$ref" => "project_item/project_item_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let(:project_item) do
          create(
            :project_item,
            project: project,
            user_secrets: {
              key: "value"
            },
            offer: create(:offer, primary_oms: oms)
          )
        end

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)

          serialized = Api::V1::ProjectItemSerializer.new(project_item).as_json
          serialized[:user_secrets] = serialized[:user_secrets].transform_values { |_| "<OBFUSCATED>" }

          expect(data).to eq(serialized.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        let(:pi_id) { 1 }
        let(:"X-User-Token") { "asdasdasd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized to access this OMS" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 1 }
        let(:pi_id) { 1 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:other_oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [other_oms_admin]) }
        let(:project_item1) { create(:project_item, offer: create(:offer, primary_oms: oms), iid: 1) }
        let(:project_item2) { create(:project_item, offer: create(:offer, primary_oms: other_oms), iid: 2) }
        let(:project) { create(:project, project_items: [project_item1, project_item2]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item1.iid }
        let(:"X-User-Token") { other_oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:p_id) { 9999 }
        let(:pi_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 9999 }
        let(:pi_id) { 9999 }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.deep_stringify_keys)
        end
      end

      response 404, "project item not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item1) { create(:project_item, offer: create(:offer, primary_oms: oms), iid: 1) }
        let(:project_item2) { create(:project_item, offer: create(:offer, primary_oms: other_oms), iid: 2) }
        let(:project) { create(:project, project_items: [project_item1, project_item2]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item2.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project item not found" }.deep_stringify_keys)
        end
      end
    end

    patch "updates a project item" do
      tags "Project items"
      produces "application/json"
      consumes "application/json"
      security [authentication_token: []]
      parameter name: :project_item_payload, in: :body, schema: { "$ref" => "project_item/project_item_update.json" }

      response 200, "project item updated" do
        schema "$ref" => "project_item/project_item_read.json"

        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let(:project_item) do
          create(
            :project_item,
            status_type: :created,
            project: project,
            status: "old value",
            user_secrets: {
              other: "something"
            },
            offer: build(:offer, primary_oms: oms)
          )
        end

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:project_item_payload) { { status: { value: "new value", type: "ready" }, user_secrets: { key: "value" } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq({ value: "new value", type: "ready" }.deep_stringify_keys)
          expect(data["user_secrets"]).to eq({ other: "<OBFUSCATED>", key: "value" }.deep_stringify_keys)

          project_item.reload
          expect(project_item.status).to eq("new value")
          expect(project_item.status_type).to eq("ready")
          expect(project_item.user_secrets).to eq({ other: "something", key: "value" }.deep_stringify_keys)
        end
      end

      response 400, "bad request" do
        schema "$ref" => "error.json"

        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) do
          create(:project_item, status_type: "created", status: "old value", offer: create(:offer, primary_oms: oms))
        end
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:project_item_payload) { { status: { value: "new value", type: "LOL" } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            {
              error:
                "The property '#/status/type' value \"LOL\" did not match one of the following values: rejected, waiting_for_response, registered, in_progress, ready, closed, approved"
            }.deep_stringify_keys
          )

          project_item.reload
          expect(project_item.status).to eq("old value")
          expect(project_item.status_type).to eq("created")
        end
      end

      response 400, "fails json validation on wrong user secrets", document: false do
        schema "$ref" => "error.json"

        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, offer: build(:offer, primary_oms: oms)) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:project_item_payload) { { user_secrets: { key: 123 } } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: { user_secrets: ["values must be strings"] } }.deep_stringify_keys)

          project_item.reload
          expect(project_item.user_secrets).to eq({})
        end
      end

      response 403, "user not authorized to access this OMS" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 1 }
        let(:pi_id) { 1 }
        let(:"X-User-Token") { user.authentication_token }
        let(:project_item_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:default_oms_admin) { create(:user) }
        let(:default_oms) { create(:default_oms, administrators: [default_oms_admin]) }
        let(:other_oms) { create(:oms) }
        let(:project_item) do
          create(
            :project_item,
            status: "ready",
            status_type: "ready",
            offer: create(:offer, primary_oms: other_oms),
            iid: 1
          )
        end
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { default_oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { default_oms_admin.authentication_token }
        let(:project_item_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)

          project_item.reload
          expect(project_item.status).to eq("ready")
          expect(project_item.status_type).to eq("ready")
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:p_id) { 9999 }
        let(:pi_id) { 9999 }
        let(:project_item_payload) { {} }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 9999 }
        let(:pi_id) { 9999 }
        let(:project_item_payload) { {} }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.deep_stringify_keys)
        end
      end

      response 404, "project item not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { 9999 }
        let(:project_item_payload) { {} }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project item not found" }.deep_stringify_keys)
        end
      end
    end
  end
end
