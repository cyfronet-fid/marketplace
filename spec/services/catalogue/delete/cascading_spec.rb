# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue::Delete::Cascading, :backend do
  let(:catalogue) { create(:catalogue) }
  let!(:provider) { create(:provider, catalogue: catalogue) }
  let!(:service) { create(:service, catalogue: catalogue) }

  before { described_class.call(catalogue) }

  it "deletes a catalogue that still has active providers and services" do
    expect(catalogue.reload.status).to eq("deleted")
  end

  it "enqueues deletion of its providers" do
    expect(DeleteJob).to have_been_enqueued.with(provider)
  end

  it "enqueues deletion of its services" do
    expect(DeleteJob).to have_been_enqueued.with(service)
  end
end
