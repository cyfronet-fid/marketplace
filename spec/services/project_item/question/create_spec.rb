# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Question::Create do
  let(:project_item_owner) { create(:user) }
  let(:project_item) { create(:project_item, user: project_item_owner) }

  context "valid question" do
    let(:question) do
      ProjectItem::Question.new(author: project_item_owner,
                          project_item: project_item, text: "Question text")
    end

    it "returns true" do
      expect(described_class.new(question).call).to be_truthy
    end

    it "creates new project_item change" do
      expect { described_class.new(question).call }.
        to change { project_item.order_changes.count }.by(1)
      last_history_entry = project_item.order_changes.last

      expect(last_history_entry.message).to eq("Question text")
      expect(last_history_entry.author).to eq(project_item_owner)
    end

    it "triggers question registration" do
      described_class.new(question).call
      last_history_entry = project_item.order_changes.last

      expect(ProjectItem::RegisterQuestionJob).
        to have_been_enqueued.with(last_history_entry)
    end
  end

  context "invalid question" do
    let(:question) do
      ProjectItem::Question.new(author: project_item_owner,
                          project_item: project_item, text: nil)
    end

    it "returns false" do
      expect(described_class.new(question).call).to be_falsy
    end

    it "does not create new project_item change" do
      expect { described_class.new(question).call }.
        to_not change { project_item.order_changes.count }
    end

    it "does not triggers question registration" do
      described_class.new(question).call

      expect(ProjectItem::RegisterQuestionJob).
        to_not have_been_enqueued
    end
  end
end
