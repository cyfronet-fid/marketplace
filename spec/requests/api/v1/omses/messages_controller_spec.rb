# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::OMSes::MessagesController, swagger_doc: "v1/ordering_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/messages" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"

    get "lists messages" do
      tags "Messages"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :project_id,
                in: :query,
                type: :integer,
                required: true,
                description: "The project to list messages of"
      parameter name: :project_item_id,
                in: :query,
                type: :integer,
                required: false,
                description: "the project item to list messages items of"
      parameter name: :from_id,
                in: :query,
                type: :integer,
                required: false,
                description: "List messages with id greater than from_id"
      parameter name: :limit, in: :query, type: :integer, required: false, description: "Number of returned elements"

      response 200, "messages found" do
        schema "$ref" => "message/message_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }

        let(:project_item1) { create(:project_item, offer: build(:offer, primary_oms: oms)) }
        let(:project_item2) { create(:project_item, offer: build(:offer, primary_oms: other_oms)) }
        let(:project) { create(:project, project_items: [project_item1, project_item2]) }

        let!(:messages) do
          [
            create(:message, id: 1, messageable: project),
            create(:message, id: 2, messageable: project_item1),
            create(:message, id: 3, messageable: project_item2),
            create(:provider_message, scope: :user_direct, id: 4, messageable: project),
            create(:message, id: 5, messageable: project_item1),
            create(:message, id: 6, messageable: project_item2)
          ]
        end

        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            {
              messages: messages.values_at(0, 3).map { |m| Api::V1::MessageSerializer.new(m).as_json }
            }.deep_stringify_keys
          )
        end
      end

      response 200, "project_item messages found", document: false do
        schema "$ref" => "message/message_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }

        let(:project_item1) { create(:project_item, offer: build(:offer, primary_oms: oms), iid: 1) }
        let(:project_item2) { create(:project_item, offer: build(:offer, primary_oms: other_oms), iid: 2) }
        let(:project) { create(:project, project_items: [project_item1, project_item2]) }

        let!(:messages) do
          [
            create(:message, id: 1, messageable: project),
            create(:message, id: 2, messageable: project_item1),
            create(:message, id: 3, messageable: project_item2),
            create(:message, id: 4, messageable: project),
            create(:provider_message, scope: :user_direct, id: 5, messageable: project_item1),
            create(:message, id: 6, messageable: project_item2)
          ]
        end

        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:project_item_id) { project_item1.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            {
              messages: messages.values_at(1, 4).map { |m| Api::V1::MessageSerializer.new(m).as_json }
            }.deep_stringify_keys
          )
        end
      end

      response 200, "messages found but were empty", document: false do
        schema "$ref" => "message/message_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, offer: create(:offer, primary_oms: oms), iid: 1) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:project_item_id) { project_item.iid }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ messages: [] }.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:project_id) { 1 }
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
        let(:project_id) { 9999 }
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
        let(:project_id) { 9999 }
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
        let(:project_id) { 9999 }
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
        let(:project) { create(:project) }

        let(:oms_id) { oms.id }
        let(:project_id) { project.id }
        let(:project_item_id) { 9999 }
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
      security [authentication_token: []]
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_write.json" }

      response 201, "message created" do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [create(:project_item, offer: create(:offer, primary_oms: oms))])
        end

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: project.id,
            author: {
              uid: "uid@idp",
              email: "smith@example.com",
              name: "Joe Smith",
              role: "provider"
            },
            content: "<content>",
            scope: "public"
          }
        end
        run_test! do |response|
          project.reload
          expect(project.messages.count).to eq(1)
          message = project.messages.first
          expect(message.author_uid).to eq("uid@idp")
          expect(message.author_email).to eq("smith@example.com")
          expect(message.author_name).to eq("Joe Smith")
          expect(message.author_role).to eq("provider")
          expect(message.scope).to eq("public")

          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::MessageSerializer.new(message).as_json.deep_stringify_keys)

          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response 201, "project item message created", document: false do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project_item) { create(:project_item, offer: create(:offer, primary_oms: oms), iid: 1) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: project.id,
            project_item_id: project_item.iid,
            author: {
              email: "smith@example.com",
              name: "Joe Smith",
              role: "provider"
            },
            content: "<content>",
            scope: "user_direct"
          }
        end
        run_test! do |response|
          project_item.reload
          expect(project_item.messages.count).to eq(1)
          message = project_item.messages.first
          expect(message.author_email).to eq("smith@example.com")
          expect(message.author_name).to eq("Joe Smith")
          expect(message.author_role).to eq("provider")
          expect(message.scope).to eq("user_direct")

          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::MessageSerializer.new(message, keep_content?: true).as_json.deep_stringify_keys)

          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end

      response 400, "bad request" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [create(:project_item, offer: create(:offer, primary_oms: oms))])
        end

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          { project_id: project.id, author: { email: "<email>", name: "<name>", role: "provider" }, scope: "public" }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            { error: "The property '#/' did not contain a required property of 'content'" }.as_json.deep_stringify_keys
          )

          project.reload
          expect(project.messages.count).to eq(0)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:project_id) { 1 }

        let(:message_payload) { nil }
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
        let(:project_id) { 9999 }

        let(:message_payload) { nil }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [create(:project_item, offer: create(:offer, primary_oms: oms))])
        end

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: project.id,
            author: {
              email: "<email>",
              name: "<name>",
              role: "provider"
            },
            content: "abc",
            scope: "user_direct"
          }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)

          project.reload
          expect(project.messages.count).to eq(0)
        end
      end

      response 403, "project_item message not authorized", document: false do
        schema "$ref" => "error.json"
        let(:default_oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [default_oms_admin]) }
        let(:other_oms) { create(:oms) }
        let(:project_item) { create(:project_item, offer: create(:offer, primary_oms: other_oms), iid: 1) }
        let(:project) { create(:project, project_items: [project_item]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { default_oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: project.id,
            project_item_id: project_item.iid,
            author: {
              email: "<email>",
              name: "<name>",
              role: "provider"
            },
            content: "abc",
            scope: "user_direct"
          }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)

          project_item.reload
          expect(project_item.messages.count).to eq(0)
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:project_id) { 9999 }

        let(:message_payload) { nil }
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
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: 1,
            author: {
              email: "<email>",
              name: "<name>",
              role: "provider"
            },
            content: "<content>",
            scope: "public"
          }
        end
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Project not found" }.as_json.deep_stringify_keys)
        end
      end

      response 404, "project item not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }
        let(:project) { create(:project, project_items: []) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) do
          {
            project_id: project.id,
            project_item_id: 1,
            author: {
              email: "<email>",
              name: "<name>",
              role: "provider"
            },
            content: "<content>",
            scope: "public"
          }
        end
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

    get "retrieves a message" do
      tags "Messages"
      produces "application/json"
      security [authentication_token: []]

      response 200, "message found" do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [create(:project_item, offer: create(:offer, primary_oms: oms))])
        end
        let(:message) { create(:message, messageable: project) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::MessageSerializer.new(message).as_json.deep_stringify_keys)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:m_id) { 1 }
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
        let(:m_id) { 1 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }
        let(:oms) { create(:default_oms) }
        let(:message) { create(:message, messageable: create(:project)) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
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
        let(:m_id) { 9999 }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "message not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms, administrators: [oms_admin]) }

        let(:project_item1) { create(:project_item, offer: build(:offer, primary_oms: oms), iid: 1) }
        let(:project_item2) { create(:project_item, offer: build(:offer, primary_oms: other_oms), iid: 2) }
        let(:project) { create(:project, project_items: [project_item1, project_item2]) }

        let!(:message) { create(:message, messageable: project_item2) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Message not found" }.deep_stringify_keys)
        end
      end
    end

    patch "updates a message" do
      tags "Messages"
      produces "application/json"
      consumes "application/json"
      security [authentication_token: []]
      parameter name: :message_payload, in: :body, schema: { "$ref" => "message/message_update.json" }

      response 200, "message updated" do
        schema "$ref" => "message/message_read.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }
        let(:project) do
          create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))])
        end
        let(:message) { create(:provider_message, scope: :public, message: "Before update", messageable: project) }

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { content: "After update" } }

        run_test! do |response|
          message.reload
          project.reload

          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::MessageSerializer.new(message).as_json.deep_stringify_keys)

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
        let(:project_item) { create(:project_item, project: build(:project), offer: build(:offer, primary_oms: oms)) }
        let(:message) do
          create(:provider_message, scope: :user_direct, message: "Before update", messageable: project_item)
        end

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { content: "After update" } }

        run_test! do |response|
          message.reload
          project_item.reload

          data = JSON.parse(response.body)
          expect(data).to eq(Api::V1::MessageSerializer.new(message, keep_content?: true).as_json.deep_stringify_keys)

          expect(message.message).to eq("After update")
          expect(project_item.messages.first.message).to eq("After update")
          expect(project_item.messages.count).to eq(1)

          expect(ActionMailer::Base.deliveries.count).to eq(2)
        end
      end

      response 400, "bad request" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }
        let(:project) { create(:project) }
        let(:message) do
          create(:message, author_role: "mediator", scope: "public", message: "Before update", messageable: project)
        end

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:message_payload) { { wrong: "key" } }

        run_test! do |response|
          message.reload
          project.reload

          data = JSON.parse(response.body)
          expect(data).to eq(
            { error: "The property '#/' did not contain a required property of 'content'" }.deep_stringify_keys
          )

          expect(message.message).to eq("Before update")
          expect(project.messages.first.message).to eq("Before update")
          expect(project.messages.count).to eq(1)
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:oms_id) { 1 }
        let(:m_id) { 1 }
        let(:"X-User-Token") { "asdasdasd" }
        let(:message_payload) { {} }

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
        let(:m_id) { 1 }
        let(:"X-User-Token") { user.authentication_token }
        let(:message_payload) { {} }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)
        end
      end

      response 403, "user not authorized" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:default_oms, administrators: [oms_admin]) }
        let(:other_oms) { create(:oms) }
        let(:message) do
          create(
            :message,
            message: "before",
            scope: "user_direct",
            messageable: create(:project_item, offer: create(:offer, primary_oms: other_oms))
          )
        end

        let(:oms_id) { oms.id }
        let(:m_id) { message.id }
        let(:message_payload) { { content: "After update" } }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You are not authorized to perform this action." }.deep_stringify_keys)

          message.reload
          expect(message.message).to eq("before")
        end
      end

      response 404, "OMS not found" do
        schema "$ref" => "error.json"
        let(:user) { create(:user) }

        let(:oms_id) { 9999 }
        let(:m_id) { 9999 }
        let(:message_payload) { {} }
        let(:"X-User-Token") { user.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "OMS not found" }.deep_stringify_keys)
        end
      end

      response 404, "message not found" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:m_id) { 9999 }
        let(:message_payload) { {} }
        let(:"X-User-Token") { oms_admin.authentication_token }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Message not found" }.deep_stringify_keys)
        end
      end
    end
  end
end
