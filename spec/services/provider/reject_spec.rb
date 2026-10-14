# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Reject, backend: true do
  subject(:reject) { described_class.call(approval_request) }

  let(:first_manager) { create(:user, email: "first@manager.com") }
  let(:second_manager) { create(:user, email: "second@manager.com") }
  let(:managers) do
    [build(:data_administrator, email: first_manager.email), build(:data_administrator, email: second_manager.email)]
  end
  let(:submitter) { create(:user) }
  let(:provider) { create(:provider, status: :unpublished, data_administrators: managers) }
  let!(:approval_request) { create(:approval_request, approvable: provider, user: submitter) }

  context "when the approval request is pending" do
    it "keeps the provider unpublished" do
      expect { reject }.not_to(change { provider.reload.status }.from("unpublished"))
    end

    it "reports the rejection" do
      expect(reject).to be(true)
    end

    it "notifies the first provider manager" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).with(provider, "first@manager.com")
    end

    it "notifies the second provider manager" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).with(provider, "second@manager.com")
    end

    it "sends one email per provider manager" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).twice
    end
  end

  context "when the reject action is already assigned but not yet saved" do
    before { approval_request.assign_attributes(status: :deleted, current_action: "rejected") }

    it "notifies the provider managers" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).twice
    end
  end

  context "when the provider was changed after a request for changes" do
    before { approval_request.update_columns(last_action: "Request for completion") }

    it "notifies the provider managers" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).twice
    end
  end

  context "when the submitter is a coordinator" do
    let(:submitter) { create(:user, roles: [:coordinator]) }

    it "notifies the provider managers" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).twice
    end
  end

  context "when the same account manages the provider twice" do
    let(:managers) do
      [build(:data_administrator, email: first_manager.email), build(:data_administrator, email: first_manager.email)]
    end

    it "notifies the account once" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).once
    end
  end

  context "when a provider manager has no Marketplace account" do
    let(:managers) do
      [
        build(:data_administrator, email: first_manager.email),
        build(:data_administrator, email: "no-account@manager.com")
      ]
    end

    it "notifies only the manager with an account" do
      expect { reject }.to have_enqueued_mail(ProviderMailer, :rejected).once
    end

    it "does not notify the manager without an account" do
      expect { reject }.not_to have_enqueued_mail(ProviderMailer, :rejected).with(provider, "no-account@manager.com")
    end
  end

  context "when the approval request has already been rejected" do
    before { approval_request.update_columns(status: "deleted", last_action: "Reject") }

    it "does not notify the provider managers again" do
      expect { reject }.not_to have_enqueued_mail(ProviderMailer, :rejected)
    end

    it "reports that nothing was rejected" do
      expect(reject).to be(false)
    end
  end

  context "when the approval request was accepted" do
    before do
      provider.update_columns(status: "published")
      approval_request.update_columns(status: "deleted", last_action: "Accept")
    end

    it "keeps the provider published" do
      expect { reject }.not_to(change { provider.reload.status }.from("published"))
    end

    it "does not notify the provider managers" do
      expect { reject }.not_to have_enqueued_mail(ProviderMailer, :rejected)
    end
  end
end
