# frozen_string_literal: true

module Importable
  ACCEPTED_VOCABULARIES = {
    SUPERCATEGORY: Category,
    CATEGORY: Category,
    SUBCATEGORY: Category,
    TRL: Vocabulary::Trl,
    SCIENTIFIC_DOMAIN: ScientificDomain,
    SCIENTIFIC_SUBDOMAIN: ScientificDomain,
    TARGET_USER: TargetUser,
    ACCESS_TYPE: Vocabulary::AccessType,
    ACCESS_MODE: Vocabulary::AccessMode,
    # TODO: Add order_type as vocabulary
    # ORDER_TYPE: Vocabulary::OrderType,
    FUNDING_BODY: Vocabulary::FundingBody,
    FUNDING_PROGRAM: Vocabulary::FundingProgram,
    LIFE_CYCLE_STATUS: Vocabulary::LifeCycleStatus,
    PROVIDER_AREA_OF_ACTIVITY: Vocabulary::AreaOfActivity,
    PROVIDER_ESFRI_TYPE: Vocabulary::EsfriType,
    PROVIDER_ESFRI_DOMAIN: Vocabulary::EsfriDomain,
    PROVIDER_LEGAL_STATUS: Vocabulary::LegalStatus,
    PROVIDER_LIFE_CYCLE_STATUS: Vocabulary::ProviderLifeCycleStatus,
    PROVIDER_NETWORK: Vocabulary::Network,
    PROVIDER_SOCIETAL_GRAND_CHALLENGE: Vocabulary::SocietalGrandChallenge,
    PROVIDER_STRUCTURE_TYPE: Vocabulary::StructureType,
    PROVIDER_MERIL_SCIENTIFIC_DOMAIN: Vocabulary::MerilScientificDomain,
    PROVIDER_MERIL_SCIENTIFIC_SUBDOMAIN: Vocabulary::MerilScientificDomain,
    PROVIDER_HOSTING_LEGAL_ENTITY: Vocabulary::HostingLegalEntity,
    RELATED_PLATFORM: Platform
  }.freeze

  def map_target_users(target_users)
    TargetUser.where(eid: target_users)
  end

  def map_categories(categories)
    Category.where(eid: categories)
  end

  def map_scientific_domains(domains)
    domains.present? ? ScientificDomain.where(eid: domains) : []
  end

  def map_link(link, type = "multimedia")
    return if link&.[]("multimediaURL").blank? && link&.[]("useCaseURL").blank? && !UrlHelper.url?(link)
    case type
    when "multimedia"
      Link::MultimediaUrl.new(name: link["multimediaName"].presence, url: link["multimediaURL"] || link)
    when "use_cases"
      Link::UseCasesUrl.new(name: link["useCaseName"].presence, url: link["useCaseURL"] || link)
    end
  end

  def map_contact(contact)
    contact&.transform_keys { |k| k.to_s.underscore } || nil
  end

  def map_data_administrator(data)
    { first_name: data["name"], last_name: data["surname"], email: data["email"] }
  end

  def map_related_services(services)
    Service.joins(:sources).where("service_sources.source_type": "eosc_registry", "service_sources.eid": services)
  end

  def map_platforms(platforms)
    Platform.where(eid: platforms)
  end

  def map_funding_bodies(funding_bodies)
    Vocabulary::FundingBody.where(eid: funding_bodies)
  end

  def map_funding_programs(funding_programs)
    Vocabulary::FundingProgram.where(eid: funding_programs)
  end

  def map_access_types(access_types)
    Vocabulary::AccessType.where(eid: access_types)
  end

  def map_access_modes(aceess_modes)
    Vocabulary::AccessMode.where(eid: aceess_modes)
  end

  def map_order_type(order_type)
    order_type.gsub("order_type-", "") unless order_type.blank?
  end

  def map_legal_statuses(statuses)
    Vocabulary::LegalStatus.where(eid: statuses)
  end

  def map_hosting_legal_entity(entities)
    Vocabulary::HostingLegalEntity.where(eid: entities)
  end

  def map_trl(trl)
    Vocabulary::Trl.where(eid: trl)
  end

  def map_life_cycle_status(life_cycle_status)
    Vocabulary::LifeCycleStatus.where(eid: life_cycle_status)
  end

  def map_provider_life_cycle_status(provider_life_cycle_status)
    Vocabulary::ProviderLifeCycleStatus.where(eid: provider_life_cycle_status)
  end

  def map_networks(networks)
    Vocabulary::Network.where(eid: networks)
  end

  def map_structure_types(structure_types)
    Vocabulary::StructureType.where(eid: structure_types)
  end

  def map_esfri_domains(domains)
    Vocabulary::EsfriDomain.where(eid: domains)
  end

  def map_esfri_types(types)
    Vocabulary::EsfriType.where(eid: types)
  end

  def map_meril_scientific_domains(domains)
    Vocabulary::MerilScientificDomain.where(eid: domains)
  end

  def map_areas_of_activity(areas)
    Vocabulary::AreaOfActivity.where(eid: areas)
  end

  def map_societal_grand_challenges(challenges)
    Vocabulary::SocietalGrandChallenge.where(eid: challenges)
  end

  def map_catalogue(catalogue)
    Catalogue.find_by(pid: catalogue)
  end

  def clazz(type)
    ACCEPTED_VOCABULARIES[type.to_sym]
  end

  def map_provider(prov_eid)
    if prov_eid.present?
      Provider
        .joins(:sources)
        .find_by("provider_sources.source_type": "eosc_registry", "provider_sources.eid": prov_eid)
    end
  end
end
