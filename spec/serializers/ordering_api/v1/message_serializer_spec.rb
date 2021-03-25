# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::MessageSerializer do
  it "it properly serializes a user message" do
    message = create(:message)

    serialized = described_class.new(message).as_json
    expected = {
      id: message.id,
      author: {
        email: message.author.email,
        name: message.author.full_name,
        role: message.author_role
      },
      content: message.message,
      scope: message.scope,
      created_at: message.created_at.iso8601,
      updated_at: message.updated_at.iso8601
    }

    expect(serialized).to eq(expected)
  end

  it "it properly serializes a provider message" do
    message = create(:provider_message)

    serialized = described_class.new(message).as_json
    expected = {
      id: message.id,
      author: {
        email: message.author_email,
        name: message.author_name,
        role: message.author_role
      },
      content: message.message,
      scope: message.scope,
      created_at: message.created_at.iso8601,
      updated_at: message.updated_at.iso8601
    }

    expect(serialized).to eq(expected)
  end
end
