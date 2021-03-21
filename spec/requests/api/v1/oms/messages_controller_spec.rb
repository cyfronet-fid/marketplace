# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"


RSpec.describe "OMS Messages API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/messages" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"

    get "lists messages" do
      tags "Messages"
      produces "application/json"
      parameter name: :project_id, in: :query, type: :integer, required: true,
                description: "The project to list messages of"
      parameter name: :project_item_id, in: :query, type: :integer, required: false,
                description: "the project item to list messages items of"
      parameter name: :from_id, in: :query, type: :integer, required: false,
                description: "List messages with id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "Number of returned elements"

      response 200, "messages found" do
        schema "$ref" => "message/message_index.json"
        let(:oms_id) { 1 }
        let(:project_id) { 1 }
        run_test!
        # TODO: test functionality
      end
    end

    post "creates a message" do
      tags "Messages"
      produces "application/json"
      consumes "application/json"
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_write.json" }

      response 201, "message created" do
        schema "$ref" => "message/message_read.json"
        let(:oms_id) { 1 }
        let(:project_id) { 1 }
        let(:message_payload) {
          {
            "project_id": 1,
            "project_item_id": 1,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "user"
            },
            "content": "<content>",
            "scope": "public",
          }
        }
        run_test!
        # TODO: test functionality
      end
    end
  end

  path "/api/v1/oms/{oms_id}/messages/{m_id}" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"
    parameter name: :m_id, in: :path, type: :string, description: "Message id"

    patch "updates a message" do
      tags "Messages"
      produces "application/json"
      consumes "application/json"
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_update.json" }

      response 200, "message updated" do
        schema "$ref" => "message/message_read.json"
        let(:oms_id) { 1 }
        let(:m_id) { 1 }
        let(:message_payload) { { "content": "asd" } }
        run_test!
        # TODO: test functionality
      end
    end
  end
end
