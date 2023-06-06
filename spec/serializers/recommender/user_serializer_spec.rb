# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommender::UserSerializer, backend: true do
  it "properly serializer a user" do
    service1 = create(:service)
    service3 = create(:service)
    project1 =
      create(
        :project,
        project_items: [
          create(:project_item, offer: create(:offer, service: service1)),
          create(:project_item, offer: create(:offer, service: service3))
        ]
      )

    service2 = create(:service)
    project2 = create(:project, project_items: [create(:project_item, offer: create(:offer, service: service2))])

    user =
      create(
        :user,
        projects: [project1, project2],
        categories: create_list(:category, 2),
        scientific_domains: create_list(:scientific_domain, 2)
      )

    serialized = described_class.new(user).as_json

    expect(serialized[:id]).to eq(user.id)
    expect(serialized[:aai_uid]).to eq(user.uid)
    expect(serialized[:categories]).to match_array(user.category_ids)
    expect(serialized[:scientific_domains]).to match_array(user.scientific_domain_ids)
    expect(serialized[:accessed_services]).to eq([service1.id, service3.id, service2.id])
  end
end
