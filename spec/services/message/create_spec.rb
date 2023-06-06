# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message::Create, backend: true do
  let(:project_item_owner) { create(:user) }
  let(:project) { create(:project, user: project_item_owner) }
  let(:project_item) { create(:project_item, project: project) }

  context "valid message" do
    let(:message) do
      Message.new(
        author: project_item_owner,
        author_role: :user,
        scope: :public,
        messageable: project_item,
        message: "message text"
      )
    end

    it "returns true" do
      expect(described_class.new(message).call).to be_truthy
    end

    it "creates new project_item" do
      expect { described_class.new(message).call }.to change { project_item.messages.count }.by(1)
      last_history_entry = project_item.messages.last

      expect(last_history_entry.message).to eq("message text")
      expect(last_history_entry.author).to eq(project_item_owner)
    end

    it "triggers message registration" do
      described_class.new(message).call
      last_history_entry = project_item.messages.last

      expect(Message::RegisterMessageJob).to have_been_enqueued.with(last_history_entry)
    end
  end

  context "invalid message" do
    let(:message) { Message.new(author: project_item_owner, messageable: project_item, message: nil) }

    it "returns false" do
      expect(described_class.new(message).call).to be_falsy
    end

    it "does not create new project_item change" do
      expect { described_class.new(message).call }.to_not(change { project_item.messages.count })
    end

    it "does not trigger message registration" do
      described_class.new(message).call

      expect(Message::RegisterMessageJob).to_not have_been_enqueued
    end
  end
end
