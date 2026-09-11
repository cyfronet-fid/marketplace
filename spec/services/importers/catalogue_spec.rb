# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Catalogue, :backend do
  let(:catalogue_hash_instance) { double("Importers::Catalogue") }
  let(:parser) { JSON }

  it "returns catalogue hash from jms" do
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

  describe ".call" do
    subject(:importer) { described_class.call(data, synchronized_at) }

    let(:data) { {} }
    let(:synchronized_at) { Time.current.to_i }

    context "when publicContacts is blank" do
      it "builds empty array" do
        expect(importer[:public_contacts]).to eq([])
      end
    end

    context "when publicContacts is empty array" do
      let(:data) { { "publicContacts" => [] } }

      it "builds empty array" do
        expect(importer[:public_contacts]).to eq([])
      end
    end

    context "when publicContacts is an array of emails" do
      let(:data) { { "publicContacts" => ["john@example.com"] } }

      it "builds PublicContact[]" do
        expect(importer[:public_contacts]).to all be_a(PublicContact)
      end

      it "assigns email to PublicContact record" do
        expect(importer[:public_contacts].map(&:email)).to contain_exactly("john@example.com")
      end
    end

    context "when mainContact has fields with no matching Contact attribute" do
      let(:data) do
        {
          "mainContact" => {
            "firstName" => "Jan",
            "lastName" => "Kowalski",
            "email" => "jan@example.com",
            "role" => nil,
            "PIDs" => nil,
            "affiliations" => nil
          }
        }
      end

      it "builds a MainContact" do
        expect(importer[:main_contact]).to be_a(MainContact)
      end

      it "maps only known Contact attributes" do
        expect(importer[:main_contact].attributes).to eq(
          MainContact.new(first_name: "Jan", last_name: "Kowalski", email: "jan@example.com").attributes
        )
      end
    end

    context "when mainContact is absent" do
      it "does not build a main contact" do
        expect(importer[:main_contact]).to be_nil
      end
    end

    context "when users is absent" do
      it "builds an empty data_administrators array" do
        expect(importer[:data_administrators]).to eq([])
      end
    end

    context "when users is present" do
      let(:data) { { "users" => ["name" => "Jan", "surname" => "Kowalski", "email" => "jan@example.com"] } }

      it "builds DataAdministrator[]" do
        expect(importer[:data_administrators]).to all be_a(DataAdministrator)
      end

      it "maps user fields to a DataAdministrator record" do
        expect(importer[:data_administrators].map(&:email)).to contain_exactly("jan@example.com")
      end
    end
  end
end
