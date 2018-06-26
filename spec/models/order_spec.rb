# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:user) }
  it { should validate_presence_of(:status) }

  it { should belong_to(:user) }
  it { should belong_to(:service) }
  it { should have_many(:order_changes).dependent(:destroy) }

  describe "#new_change" do
    it "change is not created when no message and status is given" do
      order = create(:order)

      expect { order.new_change }.to_not change { OrderChange.count }
    end

    it "change order status" do
      order = create(:order, status: :created)

      order.new_change(status: :registered, message: "Order registered")
      order_change = order.order_changes.last

      expect(order).to be_registered
      expect(order_change).to be_registered
      expect(order_change.message).to eq("Order registered")
    end

    it "does not change status when only message is given" do
      order = create(:order, status: :created)

      order.new_change(message: "some update")
      order_change = order.order_changes.last

      expect(order).to be_created
      expect(order_change).to be_created
      expect(order_change.message).to eq("some update")
    end

    it "set change author" do
      order = create(:order, status: :created)
      author = create(:user)

      order.new_change(message: "update", author: author)
      order_change = order.order_changes.last

      expect(order_change.author).to eq(author)
    end
  end

  describe "#active?" do
    it "is true when processing is not done" do
      expect(build(:order, status: :created)).to be_active
      expect(build(:order, status: :registered)).to be_active
      expect(build(:order, status: :in_progress)).to be_active
    end

    it "is false when processing is done" do
      expect(build(:order, status: :ready)).to_not be_active
      expect(build(:order, status: :rejected)).to_not be_active
    end
  end
end
