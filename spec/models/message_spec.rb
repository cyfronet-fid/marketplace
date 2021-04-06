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

  context "events" do
    it "should create an event on create" do
      project = create(:project)
      message_1 = create(:message, messageable: project)

      project_item = create(:project_item, project: project)
      message_2 = create(:message, messageable: project_item)

      expect(project.events.count).to eq(1)
      expect(project_item.events.count).to eq(1)

      expect(message_1.events.count).to eq(1)
      expect(message_1.events.first.eventable).to eq(message_1)
      expect(message_1.events.first.action).to eq("create")
      expect(message_1.events.first.additional_info).to eq({ eventable_type: "Message",
                                                             project_id: project.id,
                                                             message_id: message_1.id }.stringify_keys)

      expect(message_2.events.count).to eq(1)
      expect(message_2.events.first.eventable).to eq(message_2)
      expect(message_2.events.first.action).to eq("create")
      expect(message_2.events.first.additional_info).to eq({ eventable_type: "Message",
                                                             project_id: project.id,
                                                             project_item_id: project_item.iid,
                                                             message_id: message_2.id }.stringify_keys)
    end

    it "should create an event on update" do
      project = create(:project)

      message = create(:message, messageable: project, message: "old")
      message.update(message: "new")

      expect(project.events.count).to eq(1)

      expect(message.events.count).to eq(2)
      expect(message.events.first.eventable).to eq(message)
      expect(message.events.first.action).to eq("create")
      expect(message.events.first.additional_info).to eq({ eventable_type: "Message",
                                                           project_id: project.id,
                                                           message_id: message.id }.stringify_keys)

      expect(message.events.second.eventable).to eq(message)
      expect(message.events.second.action).to eq("update")
      expect(message.events.second.updates).to contain_exactly({ field: "message", before: "old", after: "new" }.stringify_keys)
      expect(message.events.first.additional_info).to eq({ eventable_type: "Message",
                                                           project_id: project.id,
                                                           message_id: message.id }.stringify_keys)
    end

    it "should create an event on delete" do
      project = create(:project)
      message = create(:message, messageable: project)

      m_id = message.id
      message.destroy

      expect(project.events.count).to eq(1)

      expect(Event.count).to eq(3)

      expect(Event.second.eventable).to eq(nil)
      expect(Event.second.action).to eq("create")
      expect(Event.second.additional_info).to eq({ eventable_type: "Message",
                                                   project_id: project.id,
                                                   message_id: m_id }.stringify_keys)

      expect(Event.third.eventable).to eq(nil)
      expect(Event.third.action).to eq("delete")
      expect(Event.third.additional_info).to eq({ eventable_type: "Message",
                                                   project_id: project.id,
                                                   message_id: m_id }.stringify_keys)
    end
  end
end
