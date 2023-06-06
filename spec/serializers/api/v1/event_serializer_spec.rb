# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::EventSerializer, backend: true do
  let(:project) { create(:project) }
  let(:project_item) { create(:project_item, project: project) }
  let(:user_direct_message) { create(:provider_message, messageable: project_item, scope: "user_direct") }
  let(:message) { create(:provider_message, messageable: project_item, scope: "public") }

  it "properly serializes a project_item event" do
    event =
      create(
        :event,
        action: :update,
        eventable: project_item,
        updates: [
          { field: "status", before: "aaaa", after: "bbbb" },
          { field: "status_type", before: "cccc", after: "dddd" },
          { field: "user_secrets", before: "eeee", after: "ffff" }
        ]
      )

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "update",
      resource: "project_item",
      project_id: project.id,
      project_item_id: project_item.iid,
      changes: [
        { field: "status.value", before: "aaaa", after: "bbbb" },
        { field: "status.type", before: "cccc", after: "dddd" },
        { field: "user_secrets", before: "<OBFUSCATED>", after: "<OBFUSCATED>" }
      ]
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes a project event" do
    event = create(:event, action: :create, eventable: project)

    serialized = described_class.new(event).as_json
    expected = { timestamp: event.created_at.iso8601, type: "create", resource: "project", project_id: project.id }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes message event" do
    event =
      create(
        :event,
        action: :update,
        eventable: message,
        updates: [{ field: "message", before: "aaaa", after: "bbbb" }]
      )

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "update",
      resource: "message",
      project_id: project.id,
      project_item_id: project_item.iid,
      message_id: message.id,
      changes: [{ field: "content", before: "aaaa", after: "bbbb" }]
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes message (user_direct scope) event" do
    event =
      create(
        :event,
        action: :update,
        eventable: user_direct_message,
        updates: [{ field: "message", before: "aaaa", after: "bbbb" }]
      )

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "update",
      resource: "message",
      project_id: project.id,
      project_item_id: project_item.iid,
      message_id: user_direct_message.id,
      changes: [{ field: "content", before: "<OBFUSCATED>", after: "<OBFUSCATED>" }]
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end
end
