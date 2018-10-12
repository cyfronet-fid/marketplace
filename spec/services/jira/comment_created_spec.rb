# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::CommentCreated do
  let(:order) { create(:order, status: :registered) }

  it "creates new order change" do
    expect { described_class.new(order, comment(message: "msg", id: 123)).call }.
      to change { order.order_changes.count }.by(1)
  end

  it "sets message and comment id" do
    described_class.new(order, comment(message: "msg", id: "123")).call
    last_change = order.order_changes.last

    expect(last_change.message).to eq("msg")
    expect(last_change.iid).to eq(123)
  end

  it "does not change order status" do
    described_class.new(order, comment(message: "msg", id: "123")).call

    expect(order).to be_registered
    expect(order.order_changes.last).to be_registered
  end

  it "does not duplicate order changes" do
    # Such situation can occur when we are sending question from MP to jira.
    # Than jira webhood with new comment is triggered.
    order.new_change(message: "question", iid: 321)

    expect do
      described_class.new(order, comment(message: "question", id: "321")).call
    end.to_not change { order.order_changes.count }
  end

  def comment(message:, id:, author: "non@existing.pl")
    { "body" => message, "id" => id, "emailAddress" => author }
  end
end
