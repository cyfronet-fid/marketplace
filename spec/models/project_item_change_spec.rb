# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemChange, type: :model do
  it { should belong_to(:project_item) }
  it { should belong_to(:author) }

  describe "#question?" do
    it "is true when project_item change is created by project_item owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      project_item = create(:project_item, project: project)
      project_item_change = create(:project_item_change, project_item: project_item, author: owner,
                            message: "some question")

      expect(project_item_change).to be_question
    end

    it "is false when there is not change author" do
      project_item_change = create(:project_item_change, author: nil)

      expect(project_item_change).to_not be_question
    end

    it "is false when change author is not project_item owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      project_item = create(:project_item, project: project)
      project_item_change = create(:project_item_change,
                                   project_item: project_item,
                                   author: create(:user),
                                   message: "some question")

      expect(project_item_change).to_not be_question
    end
  end
end
