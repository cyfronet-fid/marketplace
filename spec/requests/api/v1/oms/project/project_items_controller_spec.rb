# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"


RSpec.describe "OMS Project items API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
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
      security [ authentication_token: [] ]
      parameter name: :from_id, in: :query, type: :integer, required: false,
                description: "List project items with project_item_id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "Number of returned elements"

      response 200, "project items found" do
        # TODO: test user_secrets obfuscation
        schema "$ref" => "project/project_item/project_item_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_items) {
          [
            create(:project_item, iid: 1),
            create(:project_item, iid: 2),
            create(:project_item, iid: 3),
            create(:project_item, iid: 4)
          ]
        }
        let(:project) { create(:project, project_items: project_items) }

        let(:from_id) { 1 }
        let(:limit) { 2 }
        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ project_items: project_items[1..2].map { |pi| OrderingApi::V1::ProjectItemSerializer.new(pi).as_json } }.deep_stringify_keys)
        end
      end

      response 200, "project items found but were empty", document: false do
        schema "$ref" => "project/project_item/project_item_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ project_items: [] }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:p_id) { 1 }
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
      security [ authentication_token: [] ]

      response 200, "project item found" do
        # TODO: test user_secrets obfuscation
        schema "$ref" => "project/project_item/project_item_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(OrderingApi::V1::ProjectItemSerializer.new(project_item).as_json.deep_stringify_keys)
        end
      end

      response 404, "project item not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { 1 }
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
      security [ authentication_token: [] ]
      parameter name: :project_item_payload, in: :body, schema: { "$ref" => "project/project_item/project_item_update.json" }

      response 200, "project item updated" do
        schema "$ref" => "project/project_item/project_item_read.json"

        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, status_type: "created", status: "old value") }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:project_item_payload) {
          {
            "status": {
              "value": "new value",
              "type": "ready"
            }
          }
        }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["status"]).to eq({ value: "new value", type: "ready" }.deep_stringify_keys)

          project_item.reload
          expect(project_item.status).to eq("new value")
          expect(project_item.status_type).to eq("ready")
        end
      end

      response 400, "project item update validation failed" do
        schema "$ref" => "error.json"

        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, status_type: "created", status: "old value") }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:p_id) { project.id }
        let(:pi_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:project_item_payload) {
          {
            "status": {
              "value": "new value",
              "type": "LOL"
            }
          }
        }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "The property '#/status/type' value \"LOL\" did not match one of the following values: rejected, waiting_for_response, registered, in_progress, ready, closed, approved" }.deep_stringify_keys)

          project_item.reload
          expect(project_item.status).to eq(project_item.status)
          expect(project_item.status_type).to eq(project_item.status_type)
        end
      end

      response 400, "project item update validation failed wrong user secrets", document: false do
        # TODO: write this test after we add user secrets to project_item
      end
    end
  end
end
