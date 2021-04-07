# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"


RSpec.describe "OMS Events API", swagger_doc: "v1/ordering/swagger.json" do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1", "ordering") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/oms/{oms_id}/events" do
    parameter name: :oms_id, in: :path, type: :string, description: "OMS id"

    get "lists events" do
      tags "Events"
      produces "application/json"
      security [ authentication_token: [] ]
      parameter name: :from_timestamp, in: :query, type: :string, required: true,
                description: "List events after, ISO8601 format"
      parameter name: :limit, in: :query, type: :integer, required: false,
                description: "number of returned elements"

      response 200, "events found" do
        schema "$ref" => "event/event_index.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let!(:project) { create(:project) }
        let!(:project_item) { create(:project_item, project: project) }
        let!(:message1) { create(:message, messageable: project) }
        let!(:message2) { create(:message, messageable: project_item) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:from_timestamp) { "2001-04-07T15:31:46+02:00" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data["events"].length).to eq(4)

          expect(data["events"][0]["type"]).to eq("create")
          expect(data["events"][0]["resource"]).to eq("project")
          expect(data["events"][0]["project_id"]).to eq(project.id)

          expect(data["events"][1]["type"]).to eq("create")
          expect(data["events"][1]["resource"]).to eq("project_item")
          expect(data["events"][1]["project_id"]).to eq(project.id)
          expect(data["events"][1]["project_item_id"]).to eq(project_item.iid)

          expect(data["events"][2]["type"]).to eq("create")
          expect(data["events"][2]["resource"]).to eq("message")
          expect(data["events"][2]["project_id"]).to eq(project.id)
          expect(data["events"][2]["message_id"]).to eq(message1.id)

          expect(data["events"][3]["type"]).to eq("create")
          expect(data["events"][3]["resource"]).to eq("message")
          expect(data["events"][3]["project_id"]).to eq(project.id)
          expect(data["events"][3]["message_id"]).to eq(message2.id)
          expect(data["events"][3]["project_item_id"]).to eq(project_item.iid)
        end
      end

      response 400, "bad request" do
        schema "$ref" => "error.json"
        let(:oms_admin) { create(:user) }
        let(:oms) { create(:oms, administrators: [oms_admin]) }

        let(:oms_id) { oms.id }
        let(:"X-User-Token") { oms_admin.authentication_token }
        let(:from_timestamp) { "asd" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "invalid date" }.stringify_keys)
        end
      end
    end
  end
end
