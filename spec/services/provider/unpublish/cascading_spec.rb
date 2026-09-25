# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Unpublish::Cascading, :backend do
  let(:provider) { create(:provider) }
  let!(:service) { create(:service, resource_organisation: provider) }

  before { described_class.call(provider) }

  it "unpublishes the provider" do
    expect(provider.reload.status).to eq("unpublished")
  end

  it "enqueues unpublishing of its published services" do
    expect(UnpublishJob).to have_been_enqueued.with(service)
  end
end
