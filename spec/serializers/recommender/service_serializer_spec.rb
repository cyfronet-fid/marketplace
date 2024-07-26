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
        platforms: create_list(:platform, 2),
        target_users: create_list(:target_user, 2),
        related_services: create_list(:service, 2),
        manual_related_services: create_list(:service, 2),
        access_modes: create_list(:access_mode, 2),
        access_types: create_list(:access_type, 2),
        trls: [create(:trl)],
        life_cycle_statuses: [create(:life_cycle_status)],
        pid: "pid",
        horizontal: true,
        research_activities: create_list(:research_activity, 2)
      )

    serialized = described_class.new(service).as_json

    expect(serialized[:id]).to eq(service.id)
    expect(serialized[:name]).to eq(service.name)
    expect(serialized[:pid]).to eq(service.pid)
    expect(serialized[:description]).to eq(service.description)
    expect(serialized[:tagline]).to eq(service.tagline)
    expect(serialized[:rating]).to eq(service.rating)
    expect(serialized[:order_type]).to eq(service.order_type)
    expect(serialized[:countries]).to eq(service.geographical_availabilities.map(&:alpha2))
    expect(serialized[:categories]).to match_array(service.category_ids)
    expect(serialized[:providers]).to match_array(service.provider_ids)
    expect(serialized[:resource_organisation]).to eq(service.resource_organisation_id)
    expect(serialized[:scientific_domains]).to match_array(service.scientific_domain_ids)
    expect(serialized[:platforms]).to match_array(service.platform_ids)
    expect(serialized[:target_users]).to match_array(service.target_user_ids)
    expect(serialized[:related_services]).to match_array(
      service.related_service_ids + service.manual_related_service_ids
    )
    expect(serialized[:access_modes]).to match_array(service.access_mode_ids)
    expect(serialized[:access_types]).to match_array(service.access_type_ids)
    expect(serialized[:trls]).to match_array(service.trl_ids)
    expect(serialized[:life_cycle_statuses]).to match_array(service.life_cycle_status_ids)
    expect(serialized[:horizontal]).to eq(service.horizontal)
    expect(serialized[:research_activities]).to match_array(service.research_activity_ids)
  end
end
