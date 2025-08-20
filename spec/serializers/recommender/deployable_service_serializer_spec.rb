# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommender::DeployableServiceSerializer, backend: true do
  it "properly serializes a deployable service" do
    deployable_service = create(:deployable_service, :with_scientific_domains)

    serialized = described_class.new(deployable_service).as_json

    expect(serialized[:id]).to eq(deployable_service.id)
    expect(serialized[:pid]).to eq(deployable_service.pid)
    expect(serialized[:name]).to eq(deployable_service.name)
    expect(serialized[:description]).to eq(deployable_service.description)
    expect(serialized[:tagline]).to eq(deployable_service.tagline)
    expect(serialized[:status]).to eq(deployable_service.status)
    expect(serialized[:resource_organisation]).to eq(deployable_service.resource_organisation.name)
    expect(serialized[:scientific_domains]).to match_array(deployable_service.scientific_domains.map(&:name))

    # Verify that scientific_domains returns names, not IDs (from CR comment fix)
    expect(serialized[:scientific_domains]).to all(be_a(String))
    expect(serialized[:scientific_domains]).not_to include(be_a(Integer))
  end
end
