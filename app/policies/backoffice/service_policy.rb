# frozen_string_literal: true

class Backoffice::ServicePolicy < Backoffice::ApplicationPolicy
  def new?
    management_role?
  end

  def create?
    management_role?
  end

  def preview?
    access?
  end

  def permitted_attributes
    [
      :type,
      :name,
      :abbreviation,
      :description,
      :tagline,
      :order_type,
      [provider_ids: []],
      [geographical_availabilities: []],
      [language_availability: []],
      [resource_geographic_locations: []],
      [target_user_ids: []],
      [link_multimedia_urls_attributes: %i[id name url _destroy]],
      [link_use_cases_urls_attributes: %i[id name url _destroy]],
      :terms_of_use_url,
      :access_policies_url,
      :resource_level_url,
      :webpage_url,
      :manual_url,
      :helpdesk_url,
      :helpdesk_email,
      :security_contact_email,
      :training_information_url,
      :privacy_policy_url,
      :restrictions,
      :status_monitoring_url,
      :maintenance_url,
      :order_url,
      :payment_model_url,
      :pricing_url,
      [funding_body_ids: []],
      [funding_program_ids: []],
      [access_type_ids: []],
      [access_mode_ids: []],
      [certifications: []],
      [standards: []],
      [grant_project_names: []],
      [open_source_technologies: []],
      [changelog: []],
      :activate_message,
      :logo,
      [trl_ids: []],
      [scientific_domain_ids: []],
      [related_platforms: []],
      [platform_ids: []],
      :tag_list,
      [category_ids: []],
      [pc_category_ids: []],
      [service_category_ids: []],
      [related_service_ids: []],
      [required_service_ids: []],
      [manual_related_service_ids: []],
      :catalogue,
      :catalogue_id,
      :status,
      :upstream_id,
      :version,
      [life_cycle_status_ids: []],
      :resource_organisation_id,
      :horizontal,
      # Datasource Policies
      :submission_policy_url,
      :preservation_policy_url,
      :version_control,
      # Datasource content
      :jurisdiction_id,
      :datasource_classification_id,
      [research_entity_type_ids: []],
      :thematic,
      :harvestable,
      # Research Product Policies
      [research_product_access_policy_ids: []],
      # Reseach Product Metadata
      [research_product_metadata_access_policy_ids: []],
      [research_activity_ids: []],
      [entity_type_scheme_ids: []],
      [persistent_identity_systems_attributes: %i[id entity_type_id entity_type_scheme_ids _destroy]],
      [link_research_product_license_urls_attributes: %i[id url name _destroy]],
      [link_research_product_metadata_license_urls_attributes: %i[id url name _destroy]],
      [main_contact_attributes: %i[id first_name last_name email phone country_phone_code organisation position]],
      [sources_attributes: %i[id source_type eid _destroy]],
      [
        public_contacts_attributes: %i[
          id
          first_name
          last_name
          email
          phone
          country_phone_code
          organisation
          position
          _destroy
        ]
      ],
      [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
    ]
  end

  private

  def project_items
    ProjectItem.joins(:offer).where(offers: { service_id: record })
  end
end
