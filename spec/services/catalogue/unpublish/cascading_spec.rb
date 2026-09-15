# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue::Unpublish::Cascading, :backend do
  let(:catalogue) { create(:catalogue) }
  let!(:provider) { create(:provider, catalogue: catalogue) }
  let!(:service) { create(:service, catalogue: catalogue) }

  before { described_class.call(catalogue) }

  it "unpublishes the catalogue" do
    expect(catalogue.reload.status).to eq("unpublished")
  end

  it "enqueues unpublishing of its published providers" do
    expect(UnpublishJob).to have_been_enqueued.with(provider)
  end

  it "enqueues unpublishing of its published services" do
    expect(UnpublishJob).to have_been_enqueued.with(service)
  end
end
