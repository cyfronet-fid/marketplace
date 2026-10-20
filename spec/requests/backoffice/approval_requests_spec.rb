# frozen_string_literal: true

require "rails_helper"

# pl reviews an approval request through ApprovalRequest::Review and mails the
# provider managers (pl-marketplace #170); marketplace and whitelabel keep the
# inline review without emails.
RSpec.describe "Backoffice: review an approval request", :backend do
  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:submitter) { create(:user) }
  let(:provider) do
    create(:provider, status: :unpublished, data_administrators: [build(:data_administrator, email: submitter.email)])
  end
  let(:approval_request) { create(:approval_request, approvable: provider, user: submitter) }
  let(:message) { "Review message" }
  let(:params) { { approval_request: { current_action: current_action, message: message } } }

  before do
    allow(Mp::Variant).to receive(:pl?).and_return(true)
    login_as(coordinator)
    patch backoffice_approval_request_path(approval_request, format: :turbo_stream), params: params
  end

  context "when the coordinator accepts the provider" do
    let(:current_action) { "accepted" }

    it "publishes the provider" do
      expect(provider.reload).to be_published
    end

    it "closes the approval request" do
      expect(approval_request.reload).to be_deleted
    end

    it "stores the coordinator message" do
      expect(approval_request.messages.count).to eq(1)
    end

    it "notifies the provider manager that the provider is approved" do
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
        "ProviderMailer",
        "approved",
        "deliver_now",
        args: [provider, submitter.email]
      )
    end
  end

  context "when the coordinator accepts the provider without a message" do
    let(:current_action) { "accepted" }
    let(:message) { "" }

    it "responds successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "shows the success notice" do
      expect(response.body).to include("Message sent successfully")
    end

    it "publishes the provider" do
      expect(provider.reload).to be_published
    end

    it "does not store an empty message" do
      expect(Message.count).to eq(0)
    end
  end

  context "when the coordinator requests changes" do
    let(:current_action) { "requested_for_changes" }

    it "stores the coordinator message once" do
      expect(approval_request.messages.count).to eq(1)
    end

    it "keeps the message unedited" do
      expect(approval_request.messages.last).not_to be_edited
    end

    it "keeps the approval request open" do
      expect(approval_request.reload).to be_published
    end

    it "notifies the provider manager with the coordinator message" do
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
        "ProviderMailer",
        "changes_requested",
        "deliver_now",
        args: [approval_request.messages.last, submitter.email]
      )
    end

    it "does not send the approval email" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with("ProviderMailer", "approved", any_args)
    end

    it "does not send the rejection email" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with("ProviderMailer", "rejected", any_args)
    end
  end

  context "when the coordinator requests changes without a message" do
    let(:current_action) { "requested_for_changes" }
    let(:message) { "" }

    it "responds with unprocessable entity" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "shows the error alert" do
      expect(response.body).to include("Message not sent")
    end

    it "keeps the approval request open" do
      expect(approval_request.reload).to be_published
    end

    it "does not send the changes requested email" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued
    end
  end

  context "when the coordinator only sends a message" do
    let(:current_action) { "" }
    let(:provider) do
      create(:provider, status: :published, data_administrators: [build(:data_administrator, email: submitter.email)])
    end

    it "stores the message" do
      expect(approval_request.messages.count).to eq(1)
    end

    it "does not change the provider" do
      expect(provider.reload).to be_published
    end

    it "does not send any onboarding email" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued
    end
  end

  context "when the coordinator rejects the provider" do
    let(:current_action) { "rejected" }

    it "keeps the provider unpublished" do
      expect(provider.reload).to be_unpublished
    end

    it "closes the approval request" do
      expect(approval_request.reload).to be_deleted
    end

    it "notifies the provider manager that the provider was not approved" do
      expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(
        "ProviderMailer",
        "rejected",
        "deliver_now",
        args: [provider, submitter.email]
      )
    end

    it "does not send the approval email" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with("ProviderMailer", "approved", any_args)
    end
  end

  context "when the coordinator rejects an already rejected provider" do
    let(:current_action) { "rejected" }
    let(:approval_request) { create(:approval_request, :rejected, approvable: provider, user: submitter) }

    it "does not send the rejection email again" do
      expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with("ProviderMailer", "rejected", any_args)
    end
  end
end
