# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderingApi::V1::ProjectItemSerializer do
  it "properly serializes a project_item" do
    project_item = create(:project_item, offer: build(:offer, oms_params: { a: 1, b: 2 }))

    serialized = described_class.new(project_item).as_json
    expected = {
      id: project_item.iid,
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

  it "properly serializes a project_item without oms_params" do
    project_item = create(:project_item)

    serialized = described_class.new(project_item).as_json
    expected = {
      id: project_item.iid,
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

  it "properly serializes an empty project_item" do
    project_item = ProjectItem.new

    serialized = described_class.new(project_item).as_json
    expected = {
      id: project_item.iid,
      project_id: nil,
      status: {
        value: "created",
        type: nil,
      },
      attributes: {
        category: nil,
        service: nil,
        offer: nil,
        offer_properties: [],
        platforms: [],
        request_voucher: false,
        order_type: nil,
      },
    }

    expect(serialized).to eq(expected)
  end
end
