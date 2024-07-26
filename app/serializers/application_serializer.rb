# frozen_string_literal: true

class ApplicationSerializer < ActiveModel::Serializer
  def hierarchical_to_s(hierarchical)
    result = []
    result.push(hierarchical.ancestors.to_a.append(hierarchical).map(&:name).join(">"))
    hierarchical.ancestors.to_a.map do |ancestor|
      result.push(ancestor.ancestors.to_a.append(ancestor).map(&:name).join(">"))
    end
    result
  end

  %i[categories scientific_domains meril_scientific_domains].each do |method|
    define_method method do
      object.send(method)&.map { |el| hierarchical_to_s(el) }&.flatten
    end
  end

  %i[
    providers
    access_types
    access_modes
    structure_types
    platforms
    funding_bodies
    funding_programs
    target_users
    research_activities
    networks
    esfri_domains
    areas_of_activity
    societal_grand_challenges
    bundle_goals
    capabilities_of_goals
    research_entity_types
    research_product_access_policies
    research_product_metadata_access_policies
  ].each do |method|
    define_method method do
      object.send(method)&.map(&:name)
    end
  end

  %i[country resource_geographic_locations geographical_availabilities participating_countries].each do |method|
    define_method method do
      var = object.send(method)
      var.is_a?(Array) ? var&.map(&:iso_short_name) : var&.iso_short_name
    end
  end

  %i[
    resource_organisation
    jurisdiction
    trls
    life_cycle_statuses
    legal_statuses
    hosting_legal_entities
    provider_life_cycle_statuses
    esfri_types
    datasource_classification
  ].each do |method|
    define_method method do
      var = object.send(method)
      method.to_s.pluralize == method.to_s ? var&.first&.name : var&.name
    end
  end

  %i[
    multimedia_urls
    use_cases_urls
    research_product_license_urls
    research_product_metadata_license_urls
  ].each do |method|
    define_method method do
      object.send("link_#{method}")&.map { |link| { name: link.name, url: link.url } }
    end
  end

  %i[persistent_identity_systems].each do |method|
    define_method method do
      object
        .send(method)
        &.map { |p| { entity_type: p.entity_type&.name, entity_type_schemes: p.entity_type_schemes&.map(&:name) } }
    end
  end

  %i[public_contacts created_at updated_at synchronized_at last_update rating].each do |method|
    define_method method do
      object.send(method)&.as_json
    end
  end

  %i[guidelines].each do |method|
    define_method method do
      method.name.pluralize == method.name ? object.send(method)&.map(&:title) : object.send(method)&.title
    end
  end

  def catalogues
    [object&.catalogue&.pid].compact
  end

  def eosc_if
    object.tag_list&.select { |tag| tag.downcase.start_with?("eosc::") }&.map { |tag| tag.split("::").last }
  end

  def tag_list
    object.tag_list.reject { |tag| tag.downcase.start_with?("eosc::") }
  end
end
