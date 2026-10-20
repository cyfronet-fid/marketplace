# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Create, backend: true do
  subject(:create_provider) { described_class.call(provider) }

  let(:provider) { build(:provider, status: :unpublished) }

  it "does not submit the provider for approval" do
    expect { create_provider }.not_to change(ApprovalRequest, :count)
  end

  it "does not enqueue the waiting for approval email" do
    expect { create_provider }.not_to have_enqueued_mail(ProviderMailer, :waiting_for_approval)
  end
end
