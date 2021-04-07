# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::EventSerializer do
  it "it properly serializes a project item event" do
    event = Event.create(action: :update,
                         updates: [{ field: "name", before: "zxc", after: "qwe" }],
                         additional_info: { eventable_type: "ProjectItem", project_id: 1, project_item_id: 1 })

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "update",
      resource: "project_item",
      project_id: 1,
      project_item_id: 1,
      changes: [
        {
          field: "name",
          before: "zxc",
          after: "qwe"
        }
      ]
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes a project event" do
    event = Event.create(action: :create,
                         additional_info: { eventable_type: "Project", project_id: 1 })

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "create",
      resource: "project",
      project_id: 1
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes a message event" do
    event = Event.create(action: :delete,
                         additional_info: { eventable_type: "Message", message_id: 1, project_id: 1, project_item_id: 1 })

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "delete",
      resource: "message",
      message_id: 1,
      project_id: 1,
      project_item_id: 1
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end
end
