# frozen_string_literal: true

class Importers::Provider
  include Importable

  def initialize(data, synchronized_at, source = "jms")
    @data = data
    @synchronized_at = synchronized_at
    @source = source
  end

  def call
    alternative_identifiers = Array(@data["alternativeIdentifiers"]) || []
    multimedia = Array(@data["multimedia"]) || []
    scientific_domains = @data["scientificDomains"]&.map { |sd| sd["scientificSubdomain"] } || []
    tag_list = Array(@data["tags"]) || []
    public_contacts = Array(@data["publicContacts"])&.map { |c| PublicContact.new(map_contact(c)) } || []
    certifications = Array(@data["certifications"])
    participating_countries = Array(@data["participatingCountries"]) || []
    affiliations = Array(@data["affiliations"])
    networks = Array(@data["networks"])
    structure_types = Array(@data["structureTypes"])
    esfri_domains = Array(@data["esfriDomains"])
    meril_scientific_domains = @data["merilScientificDomains"]&.map { |sd| sd["merilScientificSubdomain"] } || []
    areas_of_activity = @data["areasOfActivity"]
    societal_grand_challenges = Array(@data["societalGrandChallenges"])
    national_roadmaps = Array(@data["nationalRoadmaps"])
    data_administrators = Array(@data["users"])&.map { |da| DataAdministrator.new(map_data_administrator(da)) } || []
    location = @data["location"]

    main_contact = MainContact.new(map_contact(@data["mainContact"])) if @data["mainContact"]

    {
      alternative_identifiers: alternative_identifiers.map { |aid| map_alternative_identifier(aid) }.compact,
      ppid: fetch_ppid(alternative_identifiers),
      pid: @data["id"],
      # Basic
      name: @data["name"],
      abbreviation: @data["abbreviation"],
      website: @data["website"],
      legal_entity: @data["legalEntity"],
      nodes: map_nodes(@data["node"]),
      legal_statuses: map_legal_statuses(Array(@data["legalStatus"])),
      hosting_legal_entity_string: @data["hostingLegalEntity"],
      hosting_legal_entities: map_hosting_legal_entity(@data["hostingLegalEntity"]),
      # Marketing
      description: @data["description"],
      link_multimedia_urls: multimedia.map { |item| map_link(item) }.compact,
      # Classification
      scientific_domains: map_scientific_domains(scientific_domains),
      tag_list: tag_list,
      # Location
      street_name_and_number: location["streetNameAndNumber"],
      postal_code: location["postalCode"],
      city: location["city"],
      region: location["region"],
      country: Country.for(location["country"])&.alpha2,
      # Contact
      main_contact: main_contact,
      public_contacts: public_contacts,
      # Maturity
      provider_life_cycle_statuses: map_provider_life_cycle_status(@data["lifeCycleStatus"]),
      certifications: certifications,
      # Dependencies
      participating_countries: participating_countries,
      affiliations: affiliations,
      networks: map_networks(networks),
      catalogue: map_catalogue(@data["catalogueId"]),
      # Other
      structure_types: map_structure_types(structure_types),
      esfri_domains: map_esfri_domains(esfri_domains),
      esfri_types: map_esfri_types(@data["esfriType"]),
      meril_scientific_domains: map_meril_scientific_domains(meril_scientific_domains),
      areas_of_activity: map_areas_of_activity(areas_of_activity),
      societal_grand_challenges: map_societal_grand_challenges(societal_grand_challenges),
      national_roadmaps: national_roadmaps,
      data_administrators: data_administrators,
      synchronized_at: @synchronized_at,
      status: :published
    }
  end
end
