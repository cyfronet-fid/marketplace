# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Attributes, backend: true do
  subject(:attributes) { described_class.new(offer: offer) }

  let(:offer) do
    build(
      :offer,
      parameters: [
        build(:input_parameter, id: "image", default_value: "ubuntu-22.04"),
        build(:select_parameter, id: "size", values: %w[small large], default_value: "large"),
        build(:input_parameter, id: "notebook_url")
      ]
    )
  end
  let(:values) { attributes.attributes.to_h { |attr| [attr.id, attr.value] } }

  it "pre-fills attribute values with parameter defaults" do
    expect(values).to eq("image" => "ubuntu-22.04", "size" => "large", "notebook_url" => nil)
  end

  it "lets submitted values override the defaults" do
    attributes.update("image" => "debian-12", "size" => ["small"])

    expect(values).to include("image" => "debian-12", "size" => "small")
  end

  it "keeps submitted values over defaults in the serialized attributes" do
    attributes.update("image" => "debian-12")

    expect(attributes.to_json).to include(hash_including("id" => "image", "value" => "debian-12"))
  end

  context "with a deployable service offer" do
    let(:offer) do
      build(
        :offer,
        service: nil,
        deployable_service: build(:deployable_service),
        parameters: [build(:input_parameter, id: "dns_name"), build(:input_parameter, id: "kube_public_dns_name")]
      )
    end

    it "generates one DNS name for all DNS inputs of the order" do
      expect(values.values.uniq).to contain_exactly(match(DeployableService::DnsName::FORMAT))
    end

    it "generates a different DNS name for each order" do
      expect(described_class.new(offer: offer).attributes.first.value).not_to eq(values["dns_name"])
    end
  end

  it "does not generate DNS names for other offers" do
    offer.parameters = [build(:input_parameter, id: "dns_name")]

    expect(values["dns_name"]).to be_nil
  end
end
