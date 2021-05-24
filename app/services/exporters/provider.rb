# frozen_string_literal: true

class Exporters::Provider
  def initialize(provider)
    @provider = provider
  end

  def call
    if @provider[:pid].blank?
      @provider[:pid] = to_slug(@provider[:abbreviation] + SecureRandom.uuid)
      @provider.save
    end

    {
      id: @provider[:pid],
      name: @provider[:name],
      abbreviation: @provider[:abbreviation],
      website: @provider[:website],
      legalEntity: @provider[:legal_entity],
      legalStatus: @provider[:legal_statuses].blank? ? nil : @provider[:legal_statuses][0].eid,
      description: @provider[:description],
      logo: !@provider[:logo].blank? && @provider[:logo].attached? ? url_for(@provider[:logo]) : nil,
      multimedia: @provider[:multimedia].to_a,
      scientificDomains: scientific_domains_to_json(@provider[:scientific_domains]),
      tags: @provider.tag_list.to_a,
      location: provider_to_location_json(@provider),
      mainContact: contact_to_json(@provider[:main_contact]),
      publicContacts: !@provider.has_attribute?(:public_contacts) || @provider[:public_contacts].blank? ?
                        [] :
                        @provider[:public_contacts].map { |public_contact| contact_to_json(public_contact) },
      lifeCycleStatus: @provider[:provider_life_cycle_statuses].blank? ? nil : @provider[:provider_life_cycle_statuses][0],
      certifications: @provider[:certifications].to_a,
      hostingLegalEntity: @provider[:hosting_legal_entity].blank? ? nil : @provider[:hosting_legal_entity],
      participatingCountries: @provider[:participating_countries].to_a.map { |country| country.alpha2 },
      affiliations: @provider[:affiliations].to_a,
      networks: @provider[:networks].to_a,
      structureTypes: @provider[:structure_types].to_a,
      esfriDomains: @provider[:esfri_domains].to_a.map { |domain| domain.eid },
      esfriType: @provider[:esfri_types].blank? ? nil : @provider[:esfri_types].eid,
      merilScientificDomains: meril_scientific_domains_to_json(@provider[:meril_scientific_domains]),
      areasOfActivity: @provider[:areas_of_activity].to_a,
      societalGrandChallenges: @provider[:societal_grand_challenges].to_a,
      nationalRoadmaps: @provider[:national_roadmaps].to_a,
      users: admin_to_json(@provider[:data_administrators])
    }
  end

  private
    def to_slug(ret)
      ret.downcase
         .strip
         .gsub(/\./, "_")
         .gsub(/['`]/, "")
         .gsub(/\s*@\s*/, " at ")
         .gsub(/\s*&\s*/, " and ")
         .gsub(/\s*[^A-Za-z0-9.-]\s*/, "_")
         .gsub(/_+/, "_")
         .gsub(/\A[_.]+|[_.]+\z/, "")
         .gsub(/-+/, "_")
         .gsub(/-$/, "")
    end

    def contact_to_json(contact)
      if contact.blank?
        return nil
      end

      {
        email: contact[:email],
        firstName: contact.first_name.blank? ? nil : contact[:first_name],
        lastName: contact.last_name.blank? ? nil : contact[:last_name],
        phone: contact.phone.blank? ? nil : contact[:phone],
        position: contact.position.blank? ? nil : contact[:position]
      }
    end

    def scientific_domains_to_json(scientific_domains)
      if scientific_domains.blank?
        return []
      end

      scientific_domains
        .map { |scientific_domain| {
          scientificDomain: scientific_domain[:root][:eid],
          scientificSubdomain: scientific_domain[:eid]
        } }
    end

    def meril_scientific_domains_to_json(meril_scientific_domains)
      if meril_scientific_domains.blank?
        return []
      end

      meril_scientific_domains
        .map { |meril_scientific_domain| {
          merilScientificDomain: meril_scientific_domain[:root][:eid],
          merilScientificSubdomain: meril_scientific_domain[:eid]
        } }
    end

    def admin_to_json(admins)
      if admins.blank?
        return []
      end

      admins
        .map { |admin| {
          id: "",
          email: admin[:email],
          name: admin[:first_name],
          surname: admin[:last_name]
        } }
    end

    def provider_to_location_json(provider)
      {
        streetNameAndNumber: provider[:street_name_and_number],
        postalCode: provider[:postal_code],
        city: provider[:city],
        country: provider[:country].alpha2,
        region: provider[:region].blank? ? nil : provider[:region]
      }
    end
end
