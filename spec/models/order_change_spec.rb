# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderChange, type: :model do
  it { should belong_to(:project_item) }
  it { should belong_to(:author) }

  describe "#question?" do
    it "is true when project_item change is created by project_item owner" do
      owner = create(:user)
      project_item = create(:project_item, user: owner)
      order_change = create(:order_change, project_item: project_item, author: owner,
                            message: "some question")

      expect(order_change).to be_question
    end

    it "is false when there is not change author" do
      order_change = create(:order_change, author: nil)

      expect(order_change).to_not be_question
    end

    it "is false when change author is not project_item owner" do
      owner = create(:user)
      project_item = create(:project_item, user: owner)
      order_change = create(:order_change, project_item: project_item, author: create(:user),
                            message: "some question")

      expect(order_change).to_not be_question
    end
  end
end
