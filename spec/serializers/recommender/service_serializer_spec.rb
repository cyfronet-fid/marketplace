# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommender::ServiceSerializer, backend: true do
  it "properly serializes a service" do
    organisation = create(:provider)

    service =
      create(
        :service,
        rating: 0.0,
        categories: create_list(:category, 2),
        providers: [organisation, create(:provider)],
        resource_organisation: organisation,
        scientific_domains: create_list(:scientific_domain, 2),
        access_types: create_list(:access_type, 2),
        trls: [create(:trl)],
        pid: "pid"
      )

    serialized = described_class.new(service).as_json

    expect(serialized[:id]).to eq(service.id)
    expect(serialized[:name]).to eq(service.name)
    expect(serialized[:pid]).to eq(service.pid)
    expect(serialized[:description]).to eq(service.description)
    expect(serialized[:rating]).to eq(service.rating)
    expect(serialized[:order_type]).to eq(service.order_type)
    expect(serialized[:categories]).to match_array(service.category_ids)
    expect(serialized[:providers]).to match_array(service.provider_ids)
    expect(serialized[:resource_organisation]).to eq(service.resource_organisation_id)
    expect(serialized[:scientific_domains]).to match_array(service.scientific_domain_ids)
    expect(serialized[:access_types]).to match_array(service.access_type_ids)
    expect(serialized[:trls]).to match_array(service.trl_ids)
  end
end
