# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Ready do
  let(:order) { create(:order) }

  it "creates new order change" do
    described_class.new(order).call

    expect(order.order_changes.last).to be_ready
  end

  it "changes order status into ready on success" do
    described_class.new(order).call

    expect(order).to be_ready
  end

  it "sent email to order owner" do
    # order change email is sent only when there is more than 1 change
    order.new_change(status: :ready, message: "Order is ready")

    expect { described_class.new(order).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
