# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrdersHelper, type: :helper do
  describe "#show_rating_button?" do
    it "is false when order is not ready" do
      @order = create(:order, status: :created)
      expect(ratingable?).to be_falsy
      @order.new_change(status: :registered, message: "Order registered")
      expect(ratingable?).to be_falsy
      @order.new_change(status: :in_progress, message: "Order in progress")
      expect(ratingable?).to be_falsy
      @order.new_change(status: :rejected, message: "Order rejected")
      expect(ratingable?).to be_falsy
    end

    it "is false when order is ready but updated_at after RATE_PERIOD" do
      @order = create(:order, status: :created)
      @order.new_change(status: :ready, message: "Order ready")
      expect(ratingable?).to be_falsy
    end

    it "is false when order is ready and updated_at before RATE_PERIOD but there is service_opinion" do
      @order = create(:order, status: :created)
      @order.new_change(status: :ready, message: "Order ready")
      @order.order_changes.find_by(status: :ready).created_at = RATE_PERIOD - 1.day
      create(:service_opinion, rating: "3", order: @order)
      expect(ratingable?).to eq(false)
    end

    it "is true when order is ready and updated_at before RATE_PERIOD and no service_opinion" do
      @order = create(:order, status: :created)
      @order.new_change(status: :registered, message: "Order registered")
      travel_to(6.days.ago)
      @order.new_change(status: :ready, message: "Order ready")
      travel_back
      expect(ratingable?).to eq(true)
    end
  end
end
