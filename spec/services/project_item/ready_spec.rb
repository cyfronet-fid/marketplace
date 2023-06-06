# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Ready, backend: true do
  let(:project_item) { create(:project_item) }
  let(:issue) { double("Issue", id: 1) }
  let(:transition) { double("Transition") }

  context "(JIRA works without errors)" do
    before(:each) do
      wf_ready_id = 6
      wf_in_progress_id = 7

      jira_client =
        double(
          "Jira::Client",
          jira_project_key: "MP",
          jira_issue_type_id: 5,
          wf_in_progress_id: wf_in_progress_id,
          wf_ready_id: wf_ready_id
        )
      transition_start =
        double("Transition", id: "1", name: "____Start Progress____", to: double(id: wf_in_progress_id.to_s))
      transition_done = double("Transition", id: "2", name: "____Done____", to: double(id: wf_ready_id.to_s))
      jira_class_stub = class_double(Jira::Client).as_stubbed_const(transfer_nested_constants: true)

      message_class = double("Message", message: "test1", messageable: project_item)
      message_create_class_stub = instance_double(Message::Create)

      allow(jira_class_stub).to receive(:new).and_return(jira_client)
      allow(issue).to receive(:save).and_return(issue)
      allow(issue).to receive_message_chain(:transitions, :find) { issue }
      allow(jira_client).to receive(:create_service_issue).and_return(issue)
      allow(jira_client).to receive_message_chain(:Issue, :find) { issue }
      allow(jira_client).to receive_message_chain(:Issue, :build) { issue }
      allow(issue).to receive_message_chain(:transitions, :all) { [transition_start, transition_done] }
      allow(issue).to receive_message_chain(:transitions, :build) { transition }
      allow(transition).to receive(:save!).and_return(transition)
      allow(message_create_class_stub).to receive(:call).and_return(message_class)
    end

    it "refuses to work with ProjectItem subclass" do
      customizable_project_item = CustomizableProjectItem.find_by(id: project_item.id)
      expect { described_class.new(customizable_project_item).call }.to raise_error(ArgumentError)
    end

    it "creates new project_item status change" do
      described_class.new(project_item).call

      expect(project_item.statuses.last).to be_ready
    end

    it "changes project_item status into ready on success" do
      described_class.new(project_item).call

      expect(project_item).to be_ready
    end

    it "send email with activate message" do
      service = create(:open_access_service, activate_message: "Welcome!!!")
      offer = create(:open_access_offer, service: service)
      project_item = create(:project_item, offer: offer)

      project_item.new_status(status: "custom_created", status_type: :created)

      expect { described_class.new(project_item).call }.to change { ActionMailer::Base.deliveries.count }.by(2)

      expect(ActionMailer::Base.deliveries[-2].subject).to eq(
        "[EOSC marketplace] #{service.name} is ready - usage instructions"
      )
      expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
    end

    it "do not send email with activate message if not present" do
      service = create(:open_access_service, activate_message: " ")
      offer = create(:open_access_offer, service: service)
      project_item = create(:project_item, offer: offer)

      project_item.new_status(status: "custom_created", status_type: :created)

      expect { described_class.new(project_item).call }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
    end

    it "creates new JIRA issue and do the transition" do
      jira_client = Jira::Client.new

      expect(jira_client).to receive(:create_service_issue).with(project_item).and_return(issue)

      expect(transition).to receive(:save!).with("transition" => { "id" => "2" })

      described_class.new(project_item).call
      expect(project_item).to be_ready
    end

    context "Normal service project item" do
      it "sends ready and rate service emails to owner" do
        # project_item change email is sent only when there is more than 1 change
        project_item.new_status(status: "custom_created", status_type: :created)

        expect { described_class.new(project_item).call }.to change { ActionMailer::Base.deliveries.count }.by(2)
        expect(ActionMailer::Base.deliveries[-2].subject).to eq(
          "Status of your service access request in the EOSC Portal Marketplace has changed to READY TO USE"
        )
        expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
      end
    end

    context "With additional comment" do
      it "should create first comment message" do
        expect { described_class.new(project_item, "First message").call }.to change { project_item.messages.count }.by(
          1
        )
        last_message = project_item.messages.last

        expect(last_message.role_user?).to be_truthy
        expect(last_message.public_scope?).to be_truthy
        expect(last_message.message).to eq("First message")
      end
    end

    context "Open access service project item" do
      let(:project_item) do
        create(:project_item, offer: create(:open_access_offer, service: create(:open_access_service)))
      end

      it "sends only rate service email to owner" do
        project_item.new_status(status: "custom_ready", status_type: :ready)

        expect { described_class.new(project_item).call }.to change { ActionMailer::Base.deliveries.count }.by(1)
        expect(ActionMailer::Base.deliveries.last.subject).to eq("EOSC Portal - Rate your service")
        expect(ActionMailer::Base.deliveries.last.subject).to_not start_with("[ProjectItem #")
      end
    end

    context "no project issue set" do
      let(:project_register_service) { double("Project:Register") }
      before(:each) do
        project_register_class_stub = class_double(Project::Register).as_stubbed_const(transfer_nested_constants: true)
        allow(project_register_class_stub).to receive(:new).and_return(project_register_service)
      end

      it "should call Project::Register" do
        project_item.project.jira_uninitialized!
        expect(project_register_service).to receive(:call)
        described_class.new(project_item).call
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
