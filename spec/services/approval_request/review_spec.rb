# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApprovalRequest::Review, backend: true do
  subject(:review) { described_class.call(approval_request, reviewer: coordinator, action: action, text: text) }

  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:manager_email) { create(:user, email: "manager@provider.com").email }
  let(:provider) do
    create(:provider, status: :unpublished, data_administrators: [build(:data_administrator, email: manager_email)])
  end
  let!(:approval_request) { create(:approval_request, approvable: provider) }
  let(:text) { "Review message" }

  context "when the coordinator accepts the provider" do
    let(:action) { "accepted" }

    it "succeeds" do
      expect(review).to be_success
    end

    it "publishes the provider" do
      expect { review }.to change { provider.reload.status }.from("unpublished").to("published")
    end

    it "closes the approval request" do
      expect { review }.to change { approval_request.reload.status }.from("published").to("deleted")
    end

    it "records the decision" do
      expect { review }.to change { approval_request.reload.last_action }.from(nil).to("accepted")
    end

    it "stores the coordinator message" do
      expect { review }.to change(approval_request.messages, :count).by(1)
    end

    it "sends the approval email" do
      expect { review }.to have_enqueued_mail(ProviderMailer, :approved).with(provider, manager_email)
    end
  end

  context "when the coordinator accepts the provider without a message" do
    let(:action) { "accepted" }
    let(:text) { "" }

    it "returns no message" do
      expect(review.message).to be_nil
    end

    it "succeeds" do
      expect(review).to be_success
    end

    it "publishes the provider" do
      expect { review }.to change { provider.reload.status }.to("published")
    end

    it "does not store a message" do
      expect { review }.not_to change(Message, :count)
    end

    it "sends the approval email" do
      expect { review }.to have_enqueued_mail(ProviderMailer, :approved)
    end
  end

  context "when the coordinator rejects the provider" do
    let(:action) { "rejected" }

    it "keeps the provider unpublished" do
      expect { review }.not_to(change { provider.reload.status }.from("unpublished"))
    end

    it "closes the approval request" do
      expect { review }.to change { approval_request.reload.status }.to("deleted")
    end

    it "sends the rejection email" do
      expect { review }.to have_enqueued_mail(ProviderMailer, :rejected).with(provider, manager_email)
    end
  end

  context "when the coordinator requests more information" do
    let(:action) { "requested_for_changes" }

    it "returns the stored coordinator message" do
      expect(review.message).to have_attributes(message: "Review message", persisted?: true)
    end

    it "stores the coordinator message" do
      expect { review }.to change(approval_request.messages, :count).by(1)
    end

    it "keeps the approval request open" do
      expect { review }.not_to(change { approval_request.reload.status }.from("published"))
    end

    it "sends the stored coordinator message to the provider manager" do
      expect { review }.to have_enqueued_mail(ProviderMailer, :changes_requested).with(
        having_attributes(message: "Review message", persisted?: true),
        manager_email
      )
    end
  end

  context "when the coordinator requests more information without a message" do
    let(:action) { "requested_for_changes" }
    let(:text) { "" }

    it "fails" do
      expect(review).not_to be_success
    end

    it "reports the missing message" do
      review
      expect(approval_request.errors[:message]).to be_present
    end

    it "does not change the approval request" do
      expect { review }.not_to(change { approval_request.reload.attributes })
    end

    it "does not store a message" do
      expect { review }.not_to change(Message, :count)
    end

    it "does not send any email" do
      expect { review }.not_to have_enqueued_mail
    end
  end

  context "when the coordinator only sends a message" do
    let(:action) { "" }
    let(:provider) { create(:provider, status: :published) }

    it "succeeds" do
      expect(review).to be_success
    end

    it "stores the message" do
      expect { review }.to change(approval_request.messages, :count).by(1)
    end

    it "does not change the provider" do
      expect { review }.not_to(change { provider.reload.status }.from("published"))
    end

    it "keeps the approval request open" do
      expect { review }.not_to(change { approval_request.reload.status }.from("published"))
    end

    it "does not send any onboarding email" do
      expect { review }.not_to have_enqueued_mail(ProviderMailer)
    end
  end

  context "when the provider decision fails" do
    let(:action) { "accepted" }

    before { allow(Provider::Publish).to receive(:call).and_return(false) }

    it "fails" do
      expect(review).not_to be_success
    end

    it "does not store the message" do
      expect { review }.not_to change(Message, :count)
    end

    it "does not close the approval request" do
      expect { review }.not_to(change { approval_request.reload.status }.from("published"))
    end

    it "does not send the approval email" do
      expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
    end
  end

  context "when the approval request cannot be saved" do
    let(:action) { "accepted" }

    before { allow(approval_request).to receive(:save).and_return(false) }

    it "fails" do
      expect(review).not_to be_success
    end

    it "rolls back the provider decision" do
      expect { review }.not_to(change { provider.reload.status }.from("unpublished"))
    end

    it "does not store the message" do
      expect { review }.not_to change(Message, :count)
    end

    it "does not send the approval email" do
      expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
    end
  end

  context "when the approval request was already decided" do
    let(:action) { "accepted" }

    before do
      provider.update_columns(status: "published")
      approval_request.update_columns(status: "deleted", last_action: "Accept")
    end

    it "fails" do
      expect(review).not_to be_success
    end

    it "does not store the message" do
      expect { review }.not_to change(Message, :count)
    end

    it "does not send the approval email again" do
      expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
    end
  end
end
