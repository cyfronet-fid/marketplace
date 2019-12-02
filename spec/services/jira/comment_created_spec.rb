# frozen_string_literal: true

require "rails_helper"

RSpec.describe Jira::CommentCreated do
  let(:project_item) { create(:project_item, status: :registered) }
  let(:project) { create(:project, name: "Project") }

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
                                    id: "321", visibility: nil)).call
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
                                    id: "321", visibility: nil)).call
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

  def jira_username
    Jira::Client.new.options[:username]
  end
end
