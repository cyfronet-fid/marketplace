# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Provider do
  let(:provider_hash_instance) { double("Importers::Provider") }
  let(:parser) { Nori.new(strip_namespaces: true) }
  let(:legal_status) { create(:legal_status, eid: "provider_legal_status-public_legal_entity") }
  let(:area_of_activity) { create(:area_of_activity, eid: "provider_area_of_activity-applied_research") }
  let(:esfri_domain) { create(:esfri_domain, eid: "provider_esfri_domain-energy") }
  let(:esfri_type) { create(:esfri_type, eid: "provider_esfri_type-landmark") }
  let(:meril_scientific_domain) { create(:meril_scientific_domain,
                                         eid: "provider_meril_scientific_subdomain-other-other") }
  let(:scientific_domain) { create(:scientific_domain, eid: "scientific_subdomain-generic-generic") }
  let(:network) { create(:network, eid: "provider_network-aegis") }
  let(:provider_life_cycle_status) { create(:provider_life_cycle_status,
                                            eid: "provider_life_cycle_status-operational") }
  let(:societal_grand_challenge) { create(:societal_grand_challenge,
                                          eid: "provider_societal_grand_challenge-secure_societies") }
  let(:structure_type) { create(:structure_type, eid: "provider_structure_type-mobile") }
  let(:main_contact) { build(:main_contact, first_name: "John", last_name: "Doe", email: "john@doe.pl",
                             position: nil, organisation: nil) }
  let(:public_contact) { build(:public_contact, first_name: nil, last_name: nil, email: "g.porczyca@cyfronet.pl",
                                position: nil, organisation: nil) }
  let(:data_administrator) { build(:data_administrator, first_name: "Gaweł",
                                   last_name: "Porczyca",
                                   email: "grck@qmail.com") }


  it "should return provider hash from jms" do
    response = create(:jms_xml_provider)
    resource = parser.parse(response["resource"])
    current_time = 1613193818577
    provider_mapper = described_class.new(resource["providerBundle"]["provider"], current_time)

    correct_hash = {
      pid: "cyfronet",
      # Basic
      name: "Test-Cyfronet #3",
      abbreviation: "CYFRONET",
      website: "http://www.cyfronet.pl",
      legal_entity: true,
      legal_statuses: [legal_status],
      # Marketing
      description: "Test provider for jms queue",
      multimedia: [],
      # Classification
      scientific_domains: [scientific_domain],
      tag_list: %w[tag test cyfro],
      # Location
      street_name_and_number: "ul. Nawojki 11",
      postal_code: "30-950",
      city: "Kraków",
      region: "Lesser Poland",
      country: "PL",
      # Contact
      main_contact: main_contact,
      public_contacts: [public_contact],
      # Maturity
      provider_life_cycle_statuses: [provider_life_cycle_status],
      certifications: %w[ISO-345 ASE/EBU-2008],
      # Other
      hosting_legal_entity: "cyfronet",
      participating_countries: %w[BB AT],
      affiliations: %w[asdf test],
      networks: [network],
      structure_types: [structure_type],
      esfri_domains: [esfri_domain],
      esfri_types: [esfri_type],
      meril_scientific_domains: [meril_scientific_domain],
      areas_of_activity: [area_of_activity],
      societal_grand_challenges: [societal_grand_challenge],
      national_roadmaps: %w[test test2],
      data_administrators: [data_administrator],
      synchronized_at: current_time
    }

    imported_hash = provider_mapper.call

    expect(imported_hash[:pid]).to eq(correct_hash[:pid])
    expect(imported_hash[:name]).to eq(correct_hash[:name])
    expect(imported_hash[:abbreviation]).to eq(correct_hash[:abbreviation])
    expect(imported_hash[:website]).to eq(correct_hash[:website])
    expect(imported_hash[:legal_entity]).to eq(correct_hash[:legal_entity])
    expect(imported_hash[:legal_statuses].map).to match_array(correct_hash[:legal_statuses])

    expect(imported_hash[:description]).to eq(correct_hash[:description])
    expect(imported_hash[:multimedia]&.map).to match_array(correct_hash[:multimedia])
    expect(imported_hash[:scientific_domains]&.map).to match_array(correct_hash[:scientific_domains])
    expect(imported_hash[:tag_list]).to match_array(correct_hash[:tag_list])

    expect(imported_hash[:street_name_and_number]).to eq(correct_hash[:street_name_and_number])
    expect(imported_hash[:postal_code]).to eq(correct_hash[:postal_code])
    expect(imported_hash[:city]).to eq(correct_hash[:city])
    expect(imported_hash[:region]).to eq(correct_hash[:region])
    expect(imported_hash[:country]).to eq(correct_hash[:country])
    expect(imported_hash[:main_contact].attributes).to eq(correct_hash[:main_contact].attributes)
    expect(imported_hash[:public_contacts]&.map(&:attributes)).
      to match_array(correct_hash[:public_contacts]&.map(&:attributes))

    expect(imported_hash[:provider_life_cycle_statuses]).to match_array(correct_hash[:provider_life_cycle_statuses])
    expect(imported_hash[:certifications]).to match_array(correct_hash[:certifications])
    expect(imported_hash[:hosting_legal_entity]).to eq(correct_hash[:hosting_legal_entity])
    expect(imported_hash[:participating_countries]).to match_array(correct_hash[:participating_countries])
    expect(imported_hash[:networks]).to match_array(correct_hash[:networks])
    expect(imported_hash[:structure_types]).to match_array(correct_hash[:structure_types])
    expect(imported_hash[:esfri_domains]).to match_array(correct_hash[:esfri_domains])
    expect(imported_hash[:esfri_types]).to match_array(correct_hash[:esfri_types])
    expect(imported_hash[:meril_scientific_domains]).to match_array(correct_hash[:meril_scientific_domains])
    expect(imported_hash[:areas_of_activity]).to match_array(correct_hash[:areas_of_activity])
    expect(imported_hash[:societal_grand_challenges]).to match_array(correct_hash[:societal_grand_challenges])
    expect(imported_hash[:national_roadmaps]).to match_array(correct_hash[:national_roadmaps])
    expect(imported_hash[:data_administrators]&.map(&:attributes)).
      to match_array(correct_hash[:data_administrators]&.map(&:attributes))
    expect(imported_hash[:synchronized_at]).to eq(correct_hash[:synchronized_at])
  end
end
