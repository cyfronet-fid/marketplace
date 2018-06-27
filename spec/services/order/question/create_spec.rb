# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Question::Create do
  let(:order_owner) { create(:user) }
  let(:order) { create(:order, user: order_owner) }

  context "valid question" do
    let(:question) do
      Order::Question.new(author: order_owner,
                          order: order, text: "Question text")
    end

    it "returns true" do
      expect(described_class.new(question).call).to be_truthy
    end

    it "creates new order change" do
      expect { described_class.new(question).call }.
        to change { order.order_changes.count }.by(1)
      last_history_entry = order.order_changes.last

      expect(last_history_entry.message).to eq("Question text")
      expect(last_history_entry.author).to eq(order_owner)
    end

    it "triggers question registration" do
      described_class.new(question).call
      last_history_entry = order.order_changes.last

      expect(Order::RegisterQuestionJob).
        to have_been_enqueued.with(last_history_entry)
    end
  end

  context "invalid question" do
    let(:question) do
      Order::Question.new(author: order_owner,
                          order: order, text: nil)
    end

    it "returns false" do
      expect(described_class.new(question).call).to be_falsy
    end

    it "does not create new order change" do
      expect { described_class.new(question).call }.
        to_not change { order.order_changes.count }
    end

    it "does not triggers question registration" do
      described_class.new(question).call

      expect(Order::RegisterQuestionJob).
        to_not have_been_enqueued
    end
  end
end
