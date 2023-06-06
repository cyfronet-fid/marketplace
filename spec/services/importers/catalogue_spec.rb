# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Catalogue, backend: true do
  let(:catalogue_hash_instance) { double("Importers::Catalogue") }
  let(:parser) { Nori.new(strip_namespaces: true) }

  it "should return catalogue hash from jms" do
    response = create(:jms_xml_catalogue)
    resource = parser.parse(response["resource"])
    current_time = 1_613_193_818_577
    catalogue_mapper = described_class.new(resource["catalogueBundle"]["catalogue"], current_time)

    correct_hash = { pid: "test_dev_km", name: "test dev km" }

    imported_hash = catalogue_mapper.call

    expect(imported_hash[:pid]).to eq(correct_hash[:pid])
    expect(imported_hash[:name]).to eq(correct_hash[:name])
  end
end
