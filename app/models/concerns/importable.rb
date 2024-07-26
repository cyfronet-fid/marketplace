# frozen_string_literal: true

module Importable
  def object_status(active, suspended)
    current = active ? :published : :unpublished
    suspended && active ? :suspended : current
  end

  def map_alternative_identifier(identifier)
    AlternativeIdentifier.new(identifier_type: identifier["type"], value: identifier["value"]) if identifier.present?
  end

  def map_service_categories(service_categories)
    Vocabulary::ServiceCategory.where(eid: service_categories)
  end

  def map_target_users(target_users)
    TargetUser.where(eid: target_users)
  end

  def map_categories(categories)
    Category.where(eid: categories)
  end

  def map_research_activity_ids(research_activities)
    research_activities.present? ? Vocabulary::ResearchActivity.where(eid: research_activities).map(&:id) : []
  end

  def map_scientific_domains(domains)
    domains.present? ? ScientificDomain.where(eid: domains) : []
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def map_link(link, type = "multimedia")
    if link&.[]("multimediaURL").blank? && link&.[]("researchProductLicenseURL").blank? &&
         link&.[]("researchProductMetadataLicenseURL").blank? && link&.[]("useCaseURL").blank? && !UrlHelper.url?(link)
      return
    end
    case type
    when "multimedia"
      Link::MultimediaUrl.new(name: link&.[]("multimediaName") || "", url: link["multimediaURL"] || link)
    when "use_cases"
      Link::UseCasesUrl.new(name: link&.[]("useCaseName") || "", url: link["useCaseURL"] || link)
    when "research_product_metadata"
      Link::ResearchProductMetadataLicenseUrl.new(
        name: link&.[]("researchProductMetadataLicenseName") || "",
        url: link["researchProductMetadataLicenseURL"]
      )
    when "research_product"
      Link::ResearchProductLicenseUrl.new(
        name: link&.[]("researchProductLicenseName") || "",
        url: link["researchProductLicenseURL"]
      )
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity

  def map_persistent_identity_system(system, importer = "jms")
    return if system.blank?
    PersistentIdentitySystem.new(
      entity_type: Vocabulary::EntityType.find_by(eid: system["persistentIdentityEntityType"]),
      entity_type_schemes:
        if importer == "jms"
          Vocabulary::EntityTypeScheme.where(
            eid: system.dig("persistentIdentityEntityTypeSchemes", "persistentIdentityEntityType")
          )
        else
          Vocabulary::EntityTypeScheme.where(eid: system["persistentIdentityEntityTypeSchemes"])
        end
    )
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

  def map_jurisdiction(jurisdiction)
    Vocabulary::Jurisdiction.find_by(eid: jurisdiction)
  end

  def map_datasource_classification(classification)
    Vocabulary::DatasourceClassification.find_by(eid: classification)
  end

  def map_access_policies(policies)
    Vocabulary::ResearchProductAccessPolicy.where(eid: policies, type: "Vocabulary::ResearchProductAccessPolicy").uniq
  end

  def map_metadata_access_policies(policies)
    Vocabulary::ResearchProductMetadataAccessPolicy.where(
      eid: policies,
      type: "Vocabulary::ResearchProductMetadataAccessPolicy"
    ).uniq
  end

  def map_entity_types(types)
    Vocabulary::EntityType.where(eid: types)
  end

  def map_provider(prov_eid)
    if prov_eid.present?
      Provider.find_by(pid: prov_eid) ||
        Provider.joins(:sources).find_by(
          "provider_sources.source_type": "eosc_registry",
          "provider_sources.eid": prov_eid
        )
    end
  end

  def fetch_ppid(candidate = [])
    candidate = candidate.blank? ? nil : candidate&.find { |id| id["type"] == "EOSC PID" }
    candidate.blank? ? "" : candidate&.[]("value")
  rescue StandardError
    Rails.logger.warn "Could not fetch Persistent Identifier EOSC PID. Return blank string"
    ""
  end
end
