# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::RegisterQuestionJob do
  let(:order_owner) { create(:user) }
  let(:order) { create(:order, user: order_owner) }
  let(:register_service) { instance_double(Order::RegisterQuestion) }

  it "triggers registration process for order owner question" do
    question = create(:order_change,
                      message: "Question text",
                      order: order, author: order_owner)

    expect(Order::RegisterQuestion).to receive(:new).
      with(order, "Question text").and_return(register_service)
    expect(register_service).to receive(:call)

    described_class.perform_now(question)
  end

  it "does nothing when change is not a question" do
    question = create(:order_change,
                      message: "State change",
                      status: :registered,
                      order: order)

    expect(Order::RegisterQuestion).to_not receive(:new)

    described_class.perform_now(question)
  end
end
