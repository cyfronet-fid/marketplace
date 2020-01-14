# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::CommentActivity do
  let(:project) { create(:project, name: "Project") }
  let(:project_item) { create(:project_item, status: :registered) }

  context "comment update" do
    context "for project" do
      before(:each) {
        project.messages.create(message: "First message", iid: 123)
      }

      it "update message" do
        described_class.new(project, comment(message: "First edited message", id: 123)).call
        first_message = project.messages.last

        expect(first_message.message).to eq("First edited message")
      end

      it "send email while update message" do
        expect {
          described_class.new(project, comment(message: "First edited message", id: 123)).call
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last

        expect(email.to).to contain_exactly(project.user.email)
        expect(email.body.encoded).to match(/has been modified by the service provider/)
        expect(email.subject).to eq("Message updated")
      end

      it "create new message when spm makes the message available to the user" do
        expect {
          described_class.new(project, comment(message: "New message", id: 124)).call
        }.to change { project.messages.count }.by(1)
        first_message = project.messages.last

        expect(first_message.message).to eq("New message")
      end
    end

    context "for project_item" do
      before(:each) {
        project_item.messages.create(message: "First message", iid: 123)
      }

      it "update message" do
        described_class.new(project_item, comment(message: "First edited message", id: 123)).call
        first_message = project_item.messages.last

        expect(first_message.message).to eq("First edited message")
      end

      it "send email while update message" do
        expect {
          described_class.new(project_item, comment(message: "First edited message", id: 123)).call
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last

        expect(email.to).to contain_exactly(project_item.user.email)
        expect(email.body.encoded).to match(/has been modified by the service provider/)
        expect(email.subject).to eq("Message updated")
      end

      it "create new message when spm makes the message available to the user" do
        expect {
          described_class.new(project_item, comment(message: "New message", id: 124)).call
        }.to change { project_item.messages.count }.by(1)
        first_message = project_item.messages.last

        expect(first_message.message).to eq("New message")
      end
    end
  end

  context "create message" do
    context "for project_item" do
      it "creates new project_item message" do
        expect { described_class.new(project_item, comment(message: "msg", id: 123)).call }.
          to change { project_item.messages.count }.by(1)
      end

      it "sets message and comment id" do
        described_class.new(project_item, comment(message: "msg", id: "123")).call
        last_message = project_item.messages.last

        expect(last_message.message).to eq("msg")
        expect(last_message.iid).to eq(123)
      end

      it "does not duplicate project_item messages" do
        # Such situation can occur when we are sending question from MP to jira.
        # Than jira webhood with new comment is triggered.
        project_item.messages.create(message: "question")

        expect do
          described_class.new(project_item,
                              comment(message: "question",
                                      id: "321", name: jira_username)).call
        end.to_not change { project_item.messages.count }
      end

      it "sand email to user about response" do
        expect { described_class.new(project_item, comment(message: "response", id: 123)).call }.
          to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last

        expect(email.to).to contain_exactly(project_item.user.email)
        expect(email.body.encoded).to match(/A new message was added to your service request/)
        expect(email.subject).to eq("Question about your service access request in EOSC Portal Marketplace")
      end

      it "register messages for all and for User" do
        expect do
          described_class.new(project_item,
                              comment(message: "question",
                                      id: "321", visibility: "User")).call
          described_class.new(project_item,
                              comment(message: "question",
                                      id: "322", visibility: nil)).call
        end.to change { project_item.messages.count }.by(2)
      end

      it "does not register internal messages" do
        expect do
          described_class.new(project_item,
                              comment(message: "question",
                                      id: "321", visibility: "Admin")).call
        end.to_not change { project_item.messages.count }
      end
    end

    context "for project" do
      it "creates new project message" do
        expect { described_class.new(project, comment(message: "msg", id: 124)).call }.
          to change { project.messages.count }.by(1)
      end

      it "sets message and comment id" do
        described_class.new(project, comment(message: "msg", id: "123")).call
        last_message = project.messages.last

        expect(last_message.message).to eq("msg")
        expect(last_message.iid).to eq(123)
      end

      it "does not duplicate project messages" do
        # Such situation can occur when we are sending question from MP to jira.
        # Than jira webhood with new comment is triggered.
        project.messages.create(message: "question")

        expect do
          described_class.new(project,
                              comment(message: "question",
                                      id: "321", name: jira_username)).call
        end.to_not change { project.messages.count }
      end

      it "sand email to user about response" do
        expect { described_class.new(project, comment(message: "response", id: 123)).call }.
          to change { ActionMailer::Base.deliveries.count }.by(1)
        email = ActionMailer::Base.deliveries.last

        expect(email.to).to contain_exactly(project.user.email)
        expect(email.body.encoded).to match(/You have received a message related to your Project/)
        expect(email.subject).to eq("Question about your Project Project in EOSC Portal Marketplace")
      end

      it "register messages for all and for User" do
        expect do
          described_class.new(project,
                              comment(message: "question",
                                      id: "321", visibility: "User")).call
          described_class.new(project,
                              comment(message: "question",
                                      id: "322", visibility: nil)).call
        end.to change { project.messages.count }.by(2)
      end

      it "does not register internal messages" do
        expect do
          described_class.new(project,
                              comment(message: "question",
                                      id: "321", visibility: "Admin")).call
        end.to_not change { project.messages.count }
      end
    end

    def comment(message:, id:, email: "non@existing.pl", name: "nonexisting", visibility: "User")
      {
        "body" => message, "id" => id, "emailAddress" => email,
        "author" => { "name" => name },
        "visibility" => { "value" => visibility }
      }
    end
  end

  def comment(message:, id:, email: "non@existing.pl", name: "nonexisting", visibility: "User")
    {
      "body" => message, "id" => id, "emailAddress" => email,
      "author" => { "name" => name },
      "visibility" => { "value" => visibility }
    }
  end

  def jira_username
    Jira::Client.new.options[:username]
  end
end
