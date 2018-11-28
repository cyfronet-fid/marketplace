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

    it "is false when project_item is ready but updated_at after RATE_PERIOD" do
      @project_item = create(:project_item, status: :created)
      @project_item.new_change(status: :ready, message: "ProjectItem ready")
      expect(ratingable?).to be_falsy
    end

    it "is false when project_item is ready and updated_at before RATE_PERIOD but there is service_opinion" do
      @project_item = create(:project_item, status: :created)
      @project_item.new_change(status: :ready, message: "ProjectItem ready")
      @project_item.project_item_changes.find_by(status: :ready).created_at = RATE_PERIOD - 1.day
      create(:service_opinion, rating: "3", project_item: @project_item)
      expect(ratingable?).to eq(false)
    end

    it "is true when project_item is ready and updated_at before RATE_PERIOD and no service_opinion" do
      @project_item = create(:project_item, status: :created)
      @project_item.new_change(status: :registered, message: "ProjectItem registered")
      travel_to((RATE_AFTER_PERIOD + 1.day).ago)
      @project_item.new_change(status: :ready, message: "ProjectItem ready")
      travel_back
      expect(ratingable?).to eq(true)
    end
  end
end
