# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::DeployableServiceSerializer, backend: true do
  it "properly serializes a deployable service" do
    deployable_service = create(:deployable_service, :with_catalogue, :with_scientific_domains, :with_tags, :with_node)

    serialized = described_class.new(deployable_service).as_json

    expect(serialized[:id]).to eq(deployable_service.id)
    expect(serialized[:pid]).to eq(deployable_service.pid)
    expect(serialized[:slug]).to eq(deployable_service.slug)
    expect(serialized[:name]).to eq(deployable_service.name)
    expect(serialized[:abbreviation]).to eq(deployable_service.abbreviation)
    expect(serialized[:tagline]).to eq(deployable_service.tagline)
    expect(serialized[:description]).to eq(deployable_service.description)
    expect(serialized[:url]).to eq(deployable_service.url)
    expect(serialized[:node]).to eq(deployable_service.nodes.first&.name)
    expect(serialized[:version]).to eq(deployable_service.version)
    expect(serialized[:software_license]).to eq(deployable_service.software_license)
    expect(serialized[:creators]).to eq(deployable_service.creators)
    expect(serialized[:status]).to eq(deployable_service.status)
    expect(serialized[:resource_organisation]).to eq(deployable_service.resource_organisation.name)
    expect(serialized[:catalogue]).to eq(deployable_service.catalogue.name)
    expect(serialized[:scientific_domains]).to match_array(deployable_service.scientific_domains.map(&:name))
    expect(serialized[:tag_list]).to match_array(
      deployable_service.tag_list.reject { |tag| tag.downcase.start_with?("eosc::") }
    )
    expect(serialized[:upstream_id]).to eq(deployable_service.upstream_id)
    expect(serialized[:publication_date]).to eq(deployable_service.created_at.as_json)
    expect(serialized[:updated_at]).to eq(deployable_service.updated_at.as_json)
    expect(serialized[:synchronized_at]).to eq(deployable_service.synchronized_at&.as_json)
  end
end
