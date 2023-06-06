# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemsHelper, type: :helper, backend: true do
  describe "#show_rating_button?" do
    it "is false when project_item is not ready" do
      @project_item = create(:project_item, status: "custom_created", status_type: :created)
      expect(ratingable?).to be_falsy
      @project_item.new_status(status: "custom_registered", status_type: :registered)
      expect(ratingable?).to be_falsy
      @project_item.new_status(status: "custom_in_progress", status_type: :in_progress)
      expect(ratingable?).to be_falsy
      @project_item.new_status(status: "custom_rejected", status_type: :rejected)
      expect(ratingable?).to be_falsy
    end

    it "is false when project_item is ready but there is service_opinion" do
      @project_item = create(:project_item, status: "custom_created", status_type: :created)
      @project_item.new_status(status: "custom_ready", status_type: :ready)
      create(:service_opinion, service_rating: "3", order_rating: "3", project_item: @project_item)
      expect(ratingable?).to eq(false)
    end

    it "is true when project_item is ready and no service_opinion" do
      @project_item = create(:project_item, status: "custom_created", status_type: :created)
      @project_item.new_status(status: "custom_ready", status_type: :ready)
      expect(ratingable?).to eq(true)
    end
  end
end
