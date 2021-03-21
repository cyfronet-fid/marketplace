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
      parameter name: :from_id, in: :query, type: :integer, required: false,
                description: "List project items with project_item_id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "Number of returned elements"

      response 200, "project items found" do
        schema "$ref" => "project/project_item/project_item_index.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        run_test!
        # TODO: test functionality
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

      response 200, "project item found" do
        schema "$ref" => "project/project_item/project_item_read.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        let(:pi_id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end

    patch "updates a project item" do
      tags "Project items"
      produces "application/json"
      consumes "application/json"
      parameter name: :project_item_payload, in: :body, schema: { "$ref" => "project/project_item/project_item_write.json" }

      response 200, "project item updated" do
        schema "$ref" => "project/project_item/project_item_read.json"
        let(:oms_id) { 1 }
        let(:p_id) { 1 }
        let(:pi_id) { 1 }
        let(:project_item_payload) {
          {
            "status": {
              "value": "<status>",
              "type": "ready"
            },
            "user_secrets": {
              "secret1": "VISIBLE!"
            }
          }
        }
        run_test!
        # TODO: test functionality
      end
    end
  end
end
