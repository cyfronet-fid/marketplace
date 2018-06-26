# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderChange, type: :model do
  it { should belong_to(:order) }
  it { should belong_to(:author) }

  describe "#question?" do
    it "is true when order change is created by order owner" do
      owner = create(:user)
      order = create(:order, user: owner)
      order_change = create(:order_change, order: order, author: owner,
                            message: "some question")

      expect(order_change).to be_question
    end

    it "is false when there is not change author" do
      order_change = create(:order_change, author: nil)

      expect(order_change).to_not be_question
    end

    it "is false when change author is not order owner" do
      owner = create(:user)
      order = create(:order, user: owner)
      order_change = create(:order_change, order: order, author: create(:user),
                            message: "some question")

      expect(order_change).to_not be_question
    end
  end
end
