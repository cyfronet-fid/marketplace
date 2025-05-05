# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Catalogue, backend: true do
  let(:catalogue_hash_instance) { double("Importers::Catalogue") }
  let(:parser) { JSON }

  it "should return catalogue hash from jms" do
    response = create(:jms_json_catalogue)
    response = parser.parse(response)
    resource = response["resource"]
    current_time = 1_613_193_818_577
    catalogue_mapper = described_class.new(resource["catalogue"], current_time)

    main_contact = MainContact.new(first_name: "Test", last_name: "user", email: "a.user@cyfronet.pl")
    public_contact = PublicContact.new(email: "a.user@cyfronet.pl")

    correct_hash = {
      pid: "test_dev_km",
      name: "test dev km",
      abbreviation: "test dev km",
      affiliations: [],
      description: "description well written",
      legal_entity: true,
      city: "Krakow",
      country: "PL",
      postal_code: "30-950",
      street_name_and_number: "Nawojki 11",
      website: "http://website.org",
      participating_countries: ["PL"],
      synchronized_at: current_time
    }

    imported_hash = catalogue_mapper.call

    expect(imported_hash[:pid]).to eq(correct_hash[:pid])
    expect(imported_hash[:name]).to eq(correct_hash[:name])
    expect(imported_hash[:abbreviation]).to eq(correct_hash[:abbreviation])
    expect(imported_hash[:affiliations]).to eq(correct_hash[:affiliations])
    expect(imported_hash[:description]).to eq(correct_hash[:description])
    expect(imported_hash[:legalEntity]).to eq(correct_hash[:legalEntity])
    expect(imported_hash[:city]).to eq(correct_hash[:city])
    expect(imported_hash[:country]).to eq(correct_hash[:country])
    expect(imported_hash[:postal_code]).to eq(correct_hash[:postal_code])
    expect(imported_hash[:street_name_and_number]).to eq(correct_hash[:street_name_and_number])
    expect(imported_hash[:website]).to eq(correct_hash[:website])
    expect(imported_hash[:participating_countries]).to eq(correct_hash[:participating_countries])

    expect(imported_hash[:main_contact].attributes).to eq(main_contact.attributes)
    expect(imported_hash[:public_contacts].length).to eq(1)
    expect(imported_hash[:public_contacts][0].attributes).to eq(public_contact.attributes)
    expect(imported_hash[:synchronized_at]).to eq(correct_hash[:synchronized_at])
  end
end
