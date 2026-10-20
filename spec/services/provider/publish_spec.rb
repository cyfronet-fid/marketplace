# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Publish, backend: true do
  subject(:publish) { described_class.call(provider) }

  let(:provider) { create(:provider, status: :unpublished) }

  before { create(:approval_request, approvable: provider) }

  it "publishes the provider" do
    expect { publish }.to change { provider.reload.status }.from("unpublished").to("published")
  end

  it "does not send the approval email without a coordinator approval" do
    expect { publish }.not_to have_enqueued_mail(ProviderMailer, :approved)
  end
end
