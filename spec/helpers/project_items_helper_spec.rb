# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemsHelper, type: :helper do
  describe "#show_rating_button?" do
    it "is false when project_item is not ready" do
      @project_item = create(:project_item, status: :created)
      expect(ratingable?).to be_falsy
      @project_item.new_change(status: :registered, message: "ProjectItem registered")
      expect(ratingable?).to be_falsy
      @project_item.new_change(status: :in_progress, message: "ProjectItem in progress")
      expect(ratingable?).to be_falsy
      @project_item.new_change(status: :rejected, message: "ProjectItem rejected")
      expect(ratingable?).to be_falsy
    end

    it "is false when project_item is ready but there is service_opinion" do
      @project_item = create(:project_item, status: :created)
      @project_item.new_change(status: :ready, message: "ProjectItem ready")
      create(:service_opinion, service_rating: "3", order_rating: "3", project_item: @project_item)
      expect(ratingable?).to eq(false)
    end

    it "is true when project_item is ready and no service_opinion" do
      @project_item = create(:project_item, status: :created)
      @project_item.new_change(status: :ready, message: "ProjectItem ready")
      expect(ratingable?).to eq(true)
    end
  end
end
