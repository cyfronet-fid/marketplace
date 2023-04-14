# frozen_string_literal: true

class AddDatasourceFieldsToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :submission_policy_url, :string
    add_column :services, :preservation_policy_url, :string
    add_column :services, :jurisdiction_id, :bigint
    add_column :services, :datasource_classification_id, :bigint
    add_column :services, :version_control, :boolean
    add_column :services, :thematic, :boolean, default: false
    add_column :services, :type, :string, default: "Service"
    rename_column :services, :sla_url, :resource_level_url

    rename_column :datasources, :user_manual_url, :manual_url
    rename_column :datasources, :access_policy_url, :access_policies_url

    remove_index :persistent_identity_systems, :datasource_id
    remove_index :persistent_identity_systems, %i[datasource_id entity_type_id]
    remove_index :persistent_identity_systems, %i[id entity_type_id]
    remove_index :persistent_identity_systems, :entity_type_id

    rename_column :persistent_identity_systems, :datasource_id, :service_id

    remove_foreign_key :persistent_identity_systems, :datasources
    add_foreign_key :persistent_identity_systems, :services

    add_index :services, :pid
    add_index :persistent_identity_systems, :service_id
    add_index :persistent_identity_systems, %i[service_id entity_type_id], name: "index_persistent_id_systems"
    add_index :persistent_identity_systems, %i[id entity_type_id]
    add_index :persistent_identity_systems, :entity_type_id

    drop_table :datasource_catalogues
    drop_table :datasource_categories
    drop_table :datasource_platforms
    drop_table :datasource_providers
    drop_table :datasource_scientific_domains
    drop_table :datasource_services
    drop_table :datasource_sources
    drop_table :datasource_target_users
    drop_table :datasource_vocabularies
    drop_table :datasources
  end
end
