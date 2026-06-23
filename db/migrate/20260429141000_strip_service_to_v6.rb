# frozen_string_literal: true

class StripServiceToV6 < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  REMOVED_COLUMNS = %i[
    tagline
    geographical_availabilities
    language_availability
    resource_geographic_locations
    dedicated_for
    helpdesk_url
    manual_url
    training_information_url
    status_monitoring_url
    maintenance_url
    resource_level_url
    helpdesk_email
    security_contact_email
    payment_model_url
    pricing_url
    certifications
    standards
    open_source_technologies
    changelog
    grant_project_names
    related_platforms
    version
    last_update
    restrictions
    activate_message
    horizontal
    abbreviation
    availability_cache
    reliability_cache
    provider_id
  ].freeze

  REMOVED_VOCAB_TYPES = %w[
    Vocabulary::AccessMode
    Vocabulary::FundingBody
    Vocabulary::FundingProgram
    Vocabulary::LifeCycleStatus
    Vocabulary::MarketplaceLocation
    Vocabulary::ServiceCategory
  ].freeze

  REMOVED_LINK_TYPES = %w[Link::UseCasesUrl Link::MultimediaUrl].freeze

  def up
    add_column :services, :publishing_date, :date
    add_column :services, :resource_type, :string
    add_column :services, :urls, :string, array: true, default: []

    execute(
      "DELETE FROM service_vocabularies WHERE vocabulary_type IN (#{REMOVED_VOCAB_TYPES.map { |v| quote(v) }.join(",")})"
    )
    execute(
      "DELETE FROM links WHERE linkable_type = 'Service' AND type IN (#{REMOVED_LINK_TYPES.map { |v| quote(v) }.join(",")})"
    )

    drop_table :service_target_users, if_exists: true
    drop_table :service_related_platforms, if_exists: true
    drop_table :service_relationships, if_exists: true

    REMOVED_COLUMNS.each { |column| remove_column :services, column, if_exists: true }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
