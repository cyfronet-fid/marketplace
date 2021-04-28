# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::OfferSerializer do
  it "properly serializes an order_required internal offer" do
    offer = create(:offer,
                   parameters: [build(:constant_parameter)],
                   primary_oms: create(:oms, type: :global, custom_params: { a: { mandatory: true, default: "asd" } }),
                   oms_params: { a: "XD" },
                   order_type: :order_required)

    serialized = JSON.parse(described_class.new(offer).to_json)

    puts serialized

    expected = {
      id: offer.iid,
      name: offer.name,
      description: offer.description,
      parameters: [
        {
          id: offer.parameters.first.id,
          label: offer.parameters.first.name,
          description: offer.parameters.first.hint,
          type: offer.parameters.first.type,
          value_type: offer.parameters.first.value_type,
          value: offer.parameters.first.value
        }
      ],
      order_type: offer.order_type,
      webpage: offer.webpage,
      order_url: offer.order_url,
      internal: true,
      primary_oms_id: offer.primary_oms.id,
      oms_params: offer.oms_params
    }

    expect(serialized).to eq(expected.deep_stringify_keys)
  end

  it "properly serializes an order_required non-internal offer" do
    offer = create(:offer, parameters: [build(:constant_parameter)], order_type: :order_required, internal: false)

    serialized = JSON.parse(described_class.new(offer).to_json)

    expected = {
      id: offer.iid,
      name: offer.name,
      description: offer.description,
      parameters: [
        {
          id: offer.parameters.first.id,
          label: offer.parameters.first.name,
          description: offer.parameters.first.hint,
          type: offer.parameters.first.type,
          value_type: offer.parameters.first.value_type,
          value: offer.parameters.first.value
        }
      ],
      order_type: offer.order_type,
      webpage: offer.webpage,
      order_url: offer.order_url,
      internal: false
    }

    expect(serialized).to eq(expected.deep_stringify_keys)
  end

  it "properly serializes a non-order_required offer" do
    offer = create(:offer, order_type: :open_access, internal: false)

    serialized = JSON.parse(described_class.new(offer).to_json)

    puts serialized

    expected = {
      id: offer.iid,
      name: offer.name,
      description: offer.description,
      order_type: offer.order_type,
      parameters: [],
      webpage: offer.webpage,
      order_url: offer.order_url
    }

    expect(serialized).to eq(expected.deep_stringify_keys)
  end
end
