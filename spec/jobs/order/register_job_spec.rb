# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::RegisterJob do
  let(:order_owner) { create(:user) }
  let(:register_service) { instance_double(Order::Register) }
  let(:order) {
    order = create(:order, user: order_owner)
    expect(Order::Register).to receive(:new).
        with(order).and_return(register_service)
    next order
  }

  it "triggers registration process for order" do
    expect(register_service).to receive(:call)
    described_class.perform_now(order)
  end

  it "handles exception thrown by Order::Register" do
    expect(register_service).to receive(:call).and_raise(Order::Register::JIRAIssueCreateError.new(order))
    described_class.perform_now(order)
  end
end
