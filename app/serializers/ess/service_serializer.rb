# frozen_string_literal: true

class Ess::ServiceSerializer < ApplicationSerializer
  #TODO: unify schema to transform service for services and datasources
  attribute :slug, unless: :datasource?

  attribute :resource_level_url, key: :sla_url, unless: :datasource?
  attribute :resource_level_url, if: :datasource?

  attributes :id,
             :pid,
             :catalogues,
             :guidelines,
             :eosc_if,
             :abbreviation,
             :name,
             :tagline,
             :description,
             :order_type,
             :categories,
             :resource_organisation,
             :providers,
             :multimedia_urls,
             :use_cases_urls,
             :horizontal,
             :status,
             :scientific_domains,
             :access_types,
             :access_modes,
             :platforms,
             :funding_programs,
             :funding_bodies,
             :version,
             :terms_of_use_url,
             :status_monitoring_url,
             :training_information_url,
             :maintenance_url,
             :webpage_url,
             :order_url,
             :manual_url,
             :helpdesk_url,
             :helpdesk_email,
             :pricing_url,
             :payment_model_url,
             :changelog,
             :tag_list,
             :privacy_policy_url,
             :security_contact_email,
             :certifications,
             :standards,
             :open_source_technologies,
             :grant_project_names,
             :last_update,
             :upstream_id,
             :updated_at,
             :synchronized_at,
             :geographical_availabilities,
             :resource_geographic_locations,
             :public_contacts

  attribute :created_at, key: :publication_date
  attribute :trls, key: :trl
  attribute :life_cycle_statuses, key: :life_cycle_status
  attribute :project_items_count, key: :usage_counts_downloads
  attribute :usage_counts_views

  attribute :target_users, key: :dedicated_for
  attribute :research_activities, key: :unified_categories
  attribute :languages, key: :language_availability

  #TODO: ALL attributes to the line 77 should be included in datasource schema
  attribute :offers_count, unless: :datasource?
  attribute :access_policies_url, unless: :datasource?
  attribute :service_opinion_count, unless: :datasource?
  attribute :restrictions, unless: :datasource?
  attribute :rating, unless: :datasource?
  attribute :activate_message, unless: :datasource?
  attribute :phase, unless: :datasource?

  #TODO: to remove
  attribute :related_platforms, unless: :datasource?

  def datasource?
    object.type == "Datasource"
  end

  def phase
    nil
  end
end
