# frozen_string_literal: true

require "rails_helper"

RSpec.describe Recommender::ProjectSerializer, backend: true do
  it "properly serializes a project" do
    service1 = create(:service)
    service2 = create(:service)

    create(:service) # additional service for sanity check

    project =
      create(
        :project,
        project_items: [
          create(:project_item, offer: create(:offer, service: service1)),
          create(:project_item, offer: create(:offer, service: service1)),
          create(:project_item, offer: create(:offer, service: service2))
        ]
      )

    serialized = described_class.new(project).as_json

    expect(serialized[:id]).to eq(project.id)
    expect(serialized[:user_id]).to eq(project.user_id)
    expect(serialized[:services]).to match_array([service1.id, service1.id, service2.id])
  end

  it "properly serializes a project without project items" do
    create(:service) # additional service for sanity check

    project = create(:project)

    serialized = described_class.new(project).as_json

    expect(serialized[:id]).to eq(project.id)
    expect(serialized[:user_id]).to eq(project.user_id)
    expect(serialized[:services]).to match_array([])
  end
end
