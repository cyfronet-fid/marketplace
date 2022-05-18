# frozen_string_literal: true

module Importable
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

  def map_provider(prov_eid, eosc_registry_base_url, token: nil, retry_attempts: 3, actual_try: 0)
    if prov_eid.present?
      mapped_provider =
        Provider
          .joins(:sources)
          .find_by("provider_sources.source_type": "eosc_registry", "provider_sources.eid": prov_eid)

      if mapped_provider.nil?
        prov = Importers::Request.new(eosc_registry_base_url, "provider", token: token, id: prov_eid).call
        provider = Provider.find_or_create_by(name: prov.body["name"])
        provider.update(Importers::Provider.new(prov.body, Time.now.to_i, "rest").call)
        ProviderSource.create!(provider_id: provider.id, source_type: "eosc_registry", eid: prov_eid)
        provider
      else
        mapped_provider
      end
    end
  rescue Errno::ECONNREFUSED
    actual_try += 1
    if actual_try < retry_attempts
      Rails.logger.warn "Provider mapping connection refused, #{actual_try + 1}/#{retry_attempts} try to download"
      map_provider(
        prov_eid,
        eosc_registry_base_url,
        token: token,
        retry_attempts: retry_attempts,
        actual_try: actual_try
      )
    else
      Rails.logger.error "Maximum retry connection attempts exceeded. No mapped provider return"
      nil
    end
  end
end
