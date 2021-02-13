# frozen_string_literal: true

module Importable
  def map_target_users(target_users)
    TargetUser.where(eid: target_users)
  end

  def map_pc_categories(categories)
    Vocabulary::PcCategory.where(eid: categories)
  end

  def map_scientific_domains(domains)
    ScientificDomain.where(eid: domains)
  end

  def map_contact(contact)
    contact&.transform_keys { |k| k.to_s.underscore } || nil
  end

  def map_data_administrator(data)
    {
      first_name: data["name"],
      last_name: data["surname"],
      email: data["email"]
    }
  end

  def map_related_services(services)
    Service.joins(:sources).where("service_sources.source_type": "eic",
                                  "service_sources.eid": services)
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

  def map_provider(prov_eid, eic_base_url, token: nil, unirest: Unirest)
    mapped_provider = Provider.joins(:sources).find_by("provider_sources.source_type": "eic",
                                                       "provider_sources.eid": prov_eid)
    if mapped_provider.nil?
      prov = Importers::Request.new(eic_base_url, "provider", unirest: unirest, token: token, id: prov_eid).call
      provider  = Provider.find_or_create_by(name: prov.body["name"])
      provider.update(Importers::Provider.new(prov.body, Time.now.to_i, "rest").call)
      ProviderSource.create!(provider_id: provider.id, source_type: "eic", eid: prov_eid)
      provider
    else
      mapped_provider
    end
  end
end
