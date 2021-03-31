# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message do
  it { should belong_to(:messageable) }
  it { should validate_presence_of(:message) }
  it { should validate_presence_of(:author_role) }
  it { should validate_presence_of(:scope) }

  describe "#author" do
    context "if role_user?" do
      before { allow(subject).to receive(:role_user?).and_return(true) }
      it { should validate_presence_of(:author) }
    end

    context "if !role_user?" do
      before { allow(subject).to receive(:role_user?).and_return(false) }
      it { should_not validate_presence_of(:author) }
    end
  end

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
      message = create(:message, author: nil, author_role: :provider)

      expect(message).to_not be_question
    end

    it "is false when message author is not project_item owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      project_item = create(:project_item, project: project)
      new_message = create(:message,
                                   messageable: project_item,
                                   author: create(:user),
                                   author_role: :provider,
                                   message: "some question")

      expect(new_message).to_not be_question
    end

    it "is false when message author is not project owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      new_message = create(:message,
                                   messageable: project,
                                   author: create(:user),
                                   author_role: :provider,
                                   message: "some question")

      expect(new_message).to_not be_question
    end
  end
end
