# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::PlProfile, :backend do
  before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

  it "persists delegated fields for a new PL provider" do
    provider = create(:provider, city: "Kraków", participating_countries: %w[PL DE])

    provider.reload

    expect(provider.pl_profile).to be_persisted
    expect(provider.city).to eq("Kraków")
    expect(provider.participating_countries.map(&:alpha2)).to eq(%w[PL DE])
  end
end
