# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Register, backend: true do
  let(:project_item) { create(:project_item, offer: create(:offer)) }
  let(:issue) { double("Issue", id: 1) }

  context "(JIRA works without errors)" do
    before(:each) do
      jira_client = double("Jira::Client", jira_project_key: "MP", jira_issue_type_id: 5)
      jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)
      message_class = double("Message", message: "test1", messageable: project_item)
      message_create_class_stub = instance_double(Message::Create)

      allow(jira_class_stub).to receive(:new).and_return(jira_client)
      allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
      allow(jira_client).to receive(:create_service_issue).and_return(issue)
      allow(message_create_class_stub).to receive(:call).and_return(message_class)
      allow(issue).to receive(:save).and_return(issue)
    end

    it "refuses to work with ProjectItem subclass" do
      customizable_project_item = CustomizableProjectItem.find_by(id: project_item.id)
      expect { described_class.new(customizable_project_item).call }.to raise_error(ArgumentError)
    end

    it "creates new jira issue" do
      jira_client = Jira::Client.new

      expect(jira_client).to receive(:create_service_issue).with(project_item)

      described_class.new(project_item).call
      expect(project_item.statuses.last).to be_registered
    end

    it "creates new project_item change" do
      described_class.new(project_item).call
      expect(project_item.statuses.last).to be_registered
    end

    it "changes project_item status into registered on success" do
      described_class.new(project_item).call

      expect(project_item).to be_registered
    end

    it "sent email to project_item owner" do
      # project_item change email is sent only when there is more than 1 change
      project_item.new_status(status: "custom_created", status_type: :created)

      expect { described_class.new(project_item).call }.to_not(change { ActionMailer::Base.deliveries.count })
    end

    context "With message text" do
      it "should create first comment message" do
        expect { described_class.new(project_item, "First message").call }.to(
          change { project_item.messages.count }.by(1)
        )
        last_message = project_item.messages.last

        expect(last_message.role_user?).to be_truthy
        expect(last_message.public_scope?).to be_truthy
        expect(last_message.message).to eq("First message")
      end
    end
  end

  context "(JIRA raises Errors)" do
    let!(:jira_client) do
      client = double("Jira::Client", jira_project_key: "MP")
      jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)
      allow(jira_class_stub).to receive(:new).and_return(client)
      client
    end

    it "sets jira error and raises exception on failed jira issue creation" do
      error = Jira::Client::JIRAProjectItemIssueCreateError.new(project_item, "key" => "can not have value X")

      allow(jira_client).to receive(:create_service_issue).with(project_item).and_raise(error)

      expect { described_class.new(project_item).call }.to raise_error(error)
      expect(project_item.jira_errored?).to be_truthy
    end
  end
end
