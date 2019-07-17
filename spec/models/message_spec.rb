# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message do
  it { should belong_to(:messageable) }
  it { should validate_presence_of(:message) }

  describe "#question?" do
    it "is true when message is created by project_item owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      project_item = create(:project_item, project: project)
      new_message = create(:message, messageable: project_item, author: owner,
                            message: "some question")

      expect(new_message).to be_question
    end

    it "is true when message is created by project owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      new_message = create(:message, messageable: project, author: owner,
                            message: "some question")

      expect(new_message).to be_question
    end


    it "is false when there is not message author" do
      message = create(:message, author: nil)

      expect(message).to_not be_question
    end

    it "is false when message author is not project_item owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      project_item = create(:project_item, project: project)
      new_message = create(:message,
                                   messageable: project_item,
                                   author: create(:user),
                                   message: "some question")

      expect(new_message).to_not be_question
    end

    it "is false when message author is not project owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      new_message = create(:message,
                                   messageable: project,
                                   author: create(:user),
                                   message: "some question")

      expect(new_message).to_not be_question
    end
  end
end
