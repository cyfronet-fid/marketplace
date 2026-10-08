# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue::Suspend::Cascading, :backend do
  let(:catalogue) { create(:catalogue) }
  let!(:provider) { create(:provider, catalogue: catalogue) }
  let!(:service) { create(:service, catalogue: catalogue) }

  before { described_class.call(catalogue) }

  it "suspends the catalogue" do
    expect(catalogue.reload.status).to eq("suspended")
  end

  it "enqueues suspension of its published providers" do
    expect(SuspendJob).to have_been_enqueued.with(provider)
  end

  it "enqueues suspension of its published services" do
    expect(SuspendJob).to have_been_enqueued.with(service)
  end
end
