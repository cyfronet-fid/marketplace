# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::EventSerializer do
  let(:project) { create(:project) }
  let(:project_item) { create(:project_item, project: project) }

  it "properly serializes a project_item event" do
    event = create(:event,
                   action: :update,
                   eventable: project_item,
                   updates: [
                     { field: "name", before: "zxc", after: "qwe" },
                     { field: "user_secrets", before: "123", after: "456" },
                   ])

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "update",
      resource: "project_item",
      project_id: project.id,
      project_item_id: project_item.iid,
      changes: [
        {
          field: "name",
          before: "zxc",
          after: "qwe",
        },
        {
          field: "user_secrets",
          before: "<OBFUSCATED>",
          after: "<OBFUSCATED>",
        },
      ]
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end

  it "it properly serializes a project event" do
    event = create(:event, action: :create, eventable: project)

    serialized = described_class.new(event).as_json
    expected = {
      timestamp: event.created_at.iso8601,
      type: "create",
      resource: "project",
      project_id: project.id
    }

    expect(serialized.deep_stringify_keys).to eq(expected.deep_stringify_keys)
  end
end
