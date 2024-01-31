# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, backend: true do
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
      new_message = create(:message, messageable: project_item, author: owner, message: "some question")

      expect(new_message).to be_question
    end

    it "is true when message is created by project owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      new_message = create(:message, messageable: project, author: owner, message: "some question")

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
      new_message =
        create(
          :message,
          messageable: project_item,
          author: create(:user),
          author_role: :provider,
          message: "some question"
        )

      expect(new_message).to_not be_question
    end

    it "is false when message author is not project owner" do
      owner = create(:user)
      project = create(:project, user: owner)
      new_message =
        create(:message, messageable: project, author: create(:user), author_role: :provider, message: "some question")

      expect(new_message).to_not be_question
    end
  end

  context "eventable" do
    describe "#eventable_identity" do
      let(:project) { create(:project) }

      context "on project" do
        let(:message) { create(:message, messageable: project) }

        it "has proper identity" do
          expect(message.eventable_identity).to eq({ project_id: project.id, message_id: message.id })
        end
      end

      context "on project_item" do
        let(:project_item) { create(:project_item, project: project) }
        let(:message) { create(:message, messageable: project_item) }

        it "has proper identity" do
          expect(message.eventable_identity).to eq(
            { project_id: project.id, project_item_id: project_item.iid, message_id: message.id }
          )
        end
      end
    end

    describe "#eventable_omses" do
      let(:message) { build(:message) }

      it "delegates to the messageable" do
        ret = double
        expect(message.messageable).to receive(:eventable_omses).and_return(ret)
        expect(message.eventable_omses).to eq(ret)
      end
    end

    it "should create an event on create" do
      project = create(:project)
      message1 = create(:message, messageable: project)

      project_item = create(:project_item, project: project)
      message2 = create(:message, messageable: project_item)

      expect(project.events.count).to eq(1)
      expect(project_item.events.count).to eq(1)

      expect(message1.events.count).to eq(1)
      expect(message1.events.first.eventable).to eq(message1)
      expect(message1.events.first.action).to eq("create")

      expect(message2.events.count).to eq(1)
      expect(message2.events.first.eventable).to eq(message2)
      expect(message2.events.first.action).to eq("create")
    end

    it "should create an event on update" do
      project = create(:project)

      message = create(:message, messageable: project, message: "old")
      message.update(message: "new")

      expect(project.events.count).to eq(1)

      expect(message.events.count).to eq(2)
      expect(message.events.first.eventable).to eq(message)
      expect(message.events.first.action).to eq("create")

      expect(message.events.second.eventable).to eq(message)
      expect(message.events.second.action).to eq("update")
      expect(message.events.second.updates).to contain_exactly(
        { field: "message", before: "old", after: "new" }.stringify_keys
      )
    end
  end

  describe "#edited" do
    subject { create(:message) }

    it "should be false" do
      expect(subject.edited).to be_falsey
    end

    context "after update" do
      before { subject.update!(message: "other") }

      it "should be true" do
        expect(subject.edited).to be_truthy
      end
    end
  end

  describe "#emails" do
    context "on created" do
      let(:project) { create(:project, name: "FancyOne") }

      context "for project_item" do
        let(:project_item) { create(:project_item, project: project) }

        %i[provider mediator].each do |author_role|
          context ":role_#{author_role}?" do
            %i[public user_direct].each do |scope|
              context ":#{scope}_scope?" do
                it "sends email" do
                  expect do
                    create(:message, scope: scope, author_role: author_role, messageable: project_item)
                  end.to change { ActionMailer::Base.deliveries.count }.by(1)
                  email = ActionMailer::Base.deliveries.last

                  expect(email.to).to contain_exactly(project_item.user.email)
                  expect(email.body.encoded).to include("A new message was added to your service request")
                  expect(email.subject).to eq("Question about your service access request in EOSC Portal Marketplace")
                end
              end
            end

            context ":internal_scope?" do
              it "doesn't send email" do
                expect do
                  create(:message, scope: :internal, author_role: author_role, messageable: project_item)
                end.not_to(change { ActionMailer::Base.deliveries.count })
              end
            end
          end
        end
      end

      context "for project" do
        %i[provider mediator].each do |author_role|
          context ":role_#{author_role}?" do
            %i[public user_direct].each do |scope|
              context ":#{scope}_scope?" do
                it "sends email" do
                  expect { create(:message, scope: scope, author_role: author_role, messageable: project) }.to change {
                    ActionMailer::Base.deliveries.count
                  }.by(1)
                  email = ActionMailer::Base.deliveries.last

                  expect(email.to).to contain_exactly(project.user.email)
                  expect(email.body.encoded).to include("You have received a message related to your Project")
                  expect(email.subject).to eq("Question about your Project FancyOne in EOSC Portal Marketplace")
                end
              end
            end

            context ":internal_scope?" do
              it "doesn't send email" do
                expect { create(:message, scope: :internal, author_role: author_role, messageable: project) }.not_to(
                  change { ActionMailer::Base.deliveries.count }
                )
              end
            end
          end
        end
      end
    end

    context "on updated" do
      let(:project) { create(:project, name: "FancyOne") }

      context "for project_item" do
        let(:project_item) { create(:project_item, project: project) }

        %i[provider mediator].each do |author_role|
          context ":role_#{author_role}?" do
            %i[public user_direct].each do |scope|
              context ":#{scope}_scope?" do
                let!(:message) { create(:message, scope: scope, author_role: author_role, messageable: project_item) }

                it "sends email" do
                  expect { message.update!(message: "something else") }.to change {
                    ActionMailer::Base.deliveries.count
                  }.by(1)
                  email = ActionMailer::Base.deliveries.last

                  expect(email.to).to contain_exactly(project_item.user.email)
                  expect(email.body.encoded).to include("has been modified by the service provider")
                  expect(email.subject).to eq("Message updated")
                end
              end
            end

            context ":internal_scope?" do
              let!(:message) { create(:message, scope: :internal, author_role: author_role, messageable: project_item) }

              it "doesn't send email" do
                expect { message.update!(message: "something else") }.not_to(
                  change { ActionMailer::Base.deliveries.count }
                )
              end
            end
          end
        end
      end

      context "for project" do
        %i[provider mediator].each do |author_role|
          context ":role_#{author_role}?" do
            %i[public user_direct].each do |scope|
              context ":#{scope}_scope?" do
                let!(:message) { create(:message, scope: scope, author_role: author_role, messageable: project) }

                it "sends email" do
                  expect { message.update!(message: "something else") }.to change {
                    ActionMailer::Base.deliveries.count
                  }.by(1)
                  email = ActionMailer::Base.deliveries.last

                  expect(email.to).to contain_exactly(project.user.email)
                  expect(email.body.encoded).to include("has been modified by the service provider")
                  expect(email.subject).to eq("Message updated")
                end
              end
            end

            context ":internal_scope?" do
              let!(:message) { create(:message, scope: :internal, author_role: author_role, messageable: project) }

              it "doesn't send email" do
                expect { message.update!(message: "something else") }.not_to(
                  change { ActionMailer::Base.deliveries.count }
                )
              end
            end
          end
        end
      end
    end
  end
end
