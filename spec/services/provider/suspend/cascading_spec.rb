# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Suspend::Cascading, :backend do
  let(:provider) { create(:provider) }
  let!(:service) { create(:service, resource_organisation: provider) }

  before { described_class.call(provider) }

  it "suspends the provider" do
    expect(provider.reload.status).to eq("suspended")
  end

  it "enqueues suspension of its published services" do
    expect(SuspendJob).to have_been_enqueued.with(service)
  end
end
