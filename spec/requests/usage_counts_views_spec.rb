# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Opening a detail page" do
  let(:service) { create(:service, usage_counts_views: 42) }

  before do
    stub_request(:post, %r{/similar_services/recommendation}).to_return(
      status: 200,
      body: { recommendations: [] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "leaves the service's views unchanged" do
    expect { get service_path(service) }.not_to(change { service.reload.usage_counts_views })
  end

  it "leaves the service's views unchanged on its offers page" do
    create(:offer, service: service, status: :published)

    expect { get service_offers_path(service) }.not_to(change { service.reload.usage_counts_views })
  end

  it "leaves the provider's views unchanged" do
    provider = create(:provider, usage_counts_views: 42)

    expect { get provider_path(provider) }.not_to(change { provider.reload.usage_counts_views })
  end

  it "leaves the bundle's views unchanged" do
    bundle = create(:bundle, usage_counts_views: 42)

    expect { get service_bundle_path(bundle.service, bundle.iid) }.not_to(change { bundle.reload.usage_counts_views })
  end
end
