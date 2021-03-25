# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::ProjectItemSerializer do
  it "it properly serializes a project item" do
    project_item = create(:project_item, offer: build(:offer, oms_params: { a: 1, b: 2 }))

    serialized = described_class.new(project_item).as_json
    expected = {
      id: project_item.id,
      project_id: project_item.project.id,
      status: {
        value: project_item.status,
        type: project_item.status_type,
      },
      attributes: {
        category: project_item.service.categories&.first.name,
        service: project_item.service.name,
        offer: project_item.name,
        offer_properties: project_item.properties,
        platforms: project_item.service.platforms.pluck(:name),
        request_voucher: project_item.request_voucher,
        order_type: project_item.order_type,
      },
      oms_params: project_item.offer.oms_params
    }

    expect(serialized).to eq(expected)
  end

  it "it properly serializes a project item without oms_params" do
    project_item = create(:project_item)

    serialized = described_class.new(project_item).as_json
    expected = {
      id: project_item.id,
      project_id: project_item.project.id,
      status: {
        value: project_item.status,
        type: project_item.status_type,
      },
      attributes: {
        category: project_item.service.categories&.first.name,
        service: project_item.service.name,
        offer: project_item.name,
        offer_properties: project_item.properties,
        platforms: project_item.service.platforms.pluck(:name),
        request_voucher: project_item.request_voucher,
        order_type: project_item.order_type,
      },
    }

    expect(serialized).to eq(expected)
  end
end
