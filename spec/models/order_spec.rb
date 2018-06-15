# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:status) }

  it { should belong_to(:user) }
  it { should belong_to(:service) }
  it { should have_many(:order_changes).dependent(:destroy) }

  it "change order state" do
    order = create(:order, status: :created)
    order.new_change(:registered, "Order registered")

    order_change = order.order_changes.first

    expect(order).to be_registered
    expect(order_change).to be_registered
    expect(order_change.message).to eq("Order registered")
  end
end
