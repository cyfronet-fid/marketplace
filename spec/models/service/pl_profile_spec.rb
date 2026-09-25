# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::PlProfile, :backend do
  before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

  it "persists delegated fields for a new PL service" do
    service =
      create(
        :service,
        tagline: "PL service",
        resource_geographic_locations: %w[PL DE]
      )

    service.reload

    expect(service.pl_profile).to be_persisted
    expect(service.tagline).to eq("PL service")
    expect(service.resource_geographic_locations.map(&:alpha2)).to eq(%w[PL DE])
  end
end
