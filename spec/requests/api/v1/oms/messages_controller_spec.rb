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
      security [ authentication_token: [] ]
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
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:messages) {
          [
            create(:message, id: 1),
            create(:message, id: 2),
            create(:message, id: 3),
            create(:message, id: 4)
          ]
        }
        let(:project) { create(:project, messages: messages) }

        let(:from_id) { 1 }
        let(:limit) { 2 }
        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ messages: messages[1..2].map { |m| OrderingApi::V1::MessageSerializer.new(m).as_json } }.deep_stringify_keys)
        end
      end

      response 200, "project item messages found", document: false do
        schema "$ref" => "message/message_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:messages) {
          [
            create(:message, id: 1),
            create(:message, id: 2),
            create(:message, id: 3),
            create(:message, id: 4)
          ]
        }
        let(:project_item) { create(:project_item, messages: messages) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:from_id) { 1 }
        let(:limit) { 2 }
        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:project_item_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ messages: messages[1..2].map { |m| OrderingApi::V1::MessageSerializer.new(m).as_json } }.deep_stringify_keys)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:project_id) { 1 }
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
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:project_item_id) { 1 }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project item not found" }.deep_stringify_keys)
        end
      end
    end

    post "creates a message" do
      tags "Messages"
      produces "application/json"
      consumes "application/json"
      security [ authentication_token: [] ]
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_write.json" }

      response 201, "message created" do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) {
          {
            "project_id": project.id,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "provider"
            },
            "content": "<content>",
            "scope": "public",
          }
        }
        run_test! do |response|
          project.reload
          expect(project.messages.count).to eq(1)

          data = JSON.parse(response.body)
          expect(data).to eq(OrderingApi::V1::MessageSerializer.new(project.messages[0]).as_json.deep_stringify_keys)

          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response 201, "project item message created", document: false do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) {
          {
            "project_id": project.id,
            "project_item_id": project_item.iid,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "provider"
            },
            "content": "<content>",
            "scope": "public",
          }
        }
        run_test! do |response|
          project_item.reload
          expect(project_item.messages.count).to eq(1)

          data = JSON.parse(response.body)
          expect(data).to eq(OrderingApi::V1::MessageSerializer.new(project_item.messages[0]).as_json.deep_stringify_keys)

          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response 400, "message created validation failed" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) {
          {
            "project_id": project.id,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "provider"
            },
            "scope": "public",
          }
        }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "The property '#/' did not contain a required property of 'content'" }.as_json.deep_stringify_keys)

          project.reload
          expect(project.messages.count).to eq(0)
        end
      end

      response 404, "project not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) {
          {
            "project_id": 1,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "provider"
            },
            "content": "<content>",
            "scope": "public",
          }
        }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.as_json.deep_stringify_keys)
        end
      end

      response 404, "project item not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) {
          {
            "project_id": project.id,
            "project_item_id": 1,
            "author": {
              "email": "<email>",
              "name": "<name>",
              "role": "provider"
            },
            "content": "<content>",
            "scope": "public",
          }
        }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project item not found" }.as_json.deep_stringify_keys)
        end
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
      security [ authentication_token: [] ]
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_update.json" }

      response 200, "message updated" do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let(:message) { create(:provider_message, message: "Before update", messageable: project) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { content: "After update" } }

        run_test! do |response|
          message.reload
          project.reload

          data = JSON.parse(response.body)
          expect(data).to eq(OrderingApi::V1::MessageSerializer.new(message).as_json.deep_stringify_keys)

          expect(message.message).to eq("After update")
          expect(project.messages.first.message).to eq("After update")
          expect(project.messages.count).to eq(1)

          expect(ActionMailer::Base.deliveries.count).to eq(2)
        end
      end

      response 200, "project item message updated", document: false do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, project: build(:project)) }
        let(:message) { create(:provider_message, message: "Before update", messageable: project_item) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { content: "After update" } }

        run_test! do |response|
          message.reload
          project_item.reload

          data = JSON.parse(response.body)
          expect(data).to eq(OrderingApi::V1::MessageSerializer.new(message).as_json.deep_stringify_keys)

          expect(message.message).to eq("After update")
          expect(project_item.messages.first.message).to eq("After update")
          expect(project_item.messages.count).to eq(1)

          expect(ActionMailer::Base.deliveries.count).to eq(2)
        end
      end

      response 400, "message update validation failed" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let(:message) { create(:message, message: "Before update", messageable: project) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { wrong: "key" } }

        run_test! do |response|
          message.reload
          project.reload

          data = JSON.parse(response.body)
          expect(data).to eq({ error: "The property '#/' did not contain a required property of 'content'" }.deep_stringify_keys)

          expect(message.message).to eq("Before update")
          expect(project.messages.first.message).to eq("Before update")
          expect(project.messages.count).to eq(1)
        end
      end
    end
  end
end
