# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::Create do
  let(:user) { create(:user) }
  let(:service) { create(:service) }
  let(:order_template) { build(:order, user: user, service: service) }

  it "creates order and set initial order change" do
    order = described_class.new(order_template).call

    expect(order).to be_created
    expect(order.user).to eq(user)
    expect(order.service).to eq(service)
  end

  it "creates first order change" do
    order = described_class.new(order_template).call

    expect(order.order_changes.count).to eq(1)
    expect(order.order_changes.first).to be_created
  end

  it "triggers register order in external system" do
    order = described_class.new(order_template).call

    expect(Order::RegisterJob).to have_been_enqueued.with(order)
  end

  it "sends email to order owner" do
    expect { described_class.new(order_template).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
