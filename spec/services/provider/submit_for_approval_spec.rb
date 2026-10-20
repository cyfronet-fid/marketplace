# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::SubmitForApproval, backend: true do
  subject(:submit) { described_class.call(provider, user) }

  let(:user) { create(:user) }
  let!(:provider) do
    create(:provider, status: :unpublished, data_administrators: [build(:data_administrator, email: user.email)])
  end

  context "when a regular user submits a provider" do
    it "creates an approval request" do
      expect { submit }.to change(ApprovalRequest, :count).by(1)
    end

    it "assigns the approval request to the provider and the submitting user" do
      expect(submit).to have_attributes(approvable: provider, user: user, status: "published")
    end

    it "enqueues the waiting for approval email for the approval request" do
      expect { submit }.to have_enqueued_mail(ProviderMailer, :waiting_for_approval).with(
        having_attributes(approvable: provider, user: user)
      )
    end
  end

  context "when the provider has already been submitted" do
    let!(:existing_request) { described_class.call(provider, user) }

    it "does not create another approval request" do
      expect { submit }.not_to change(ApprovalRequest, :count)
    end

    it "returns the existing approval request" do
      expect(submit).to eq(existing_request)
    end

    it "does not enqueue another waiting for approval email" do
      expect { submit }.not_to have_enqueued_mail(ProviderMailer, :waiting_for_approval)
    end
  end

  context "when a coordinator creates a provider" do
    let(:user) { create(:user, roles: [:coordinator]) }

    it "does not create an approval request" do
      expect { submit }.not_to change(ApprovalRequest, :count)
    end

    it "does not enqueue the waiting for approval email" do
      expect { submit }.not_to have_enqueued_mail(ProviderMailer, :waiting_for_approval)
    end
  end

  context "when the user already manages a published provider" do
    before do
      create(:provider, status: :published, data_administrators: [build(:data_administrator, email: user.email)])
    end

    it "does not create an approval request" do
      expect { submit }.not_to change(ApprovalRequest, :count)
    end

    it "does not enqueue the waiting for approval email" do
      expect { submit }.not_to have_enqueued_mail(ProviderMailer, :waiting_for_approval)
    end
  end
end
