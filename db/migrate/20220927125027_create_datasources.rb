# frozen_string_literal: true

class CreateDatasources < ActiveRecord::Migration[6.1]
  def change
    create_table :datasources do |t|
      t.string :pid, null: false, index: true
      t.string :status, null: false, default: "published"
      t.string :order_type
      t.string :abbreviation
      t.string :name, null: false, index: true
      t.string :tagline
      t.text :description, null: false
      t.bigint :resource_organisation_id, null: false, index: true
      t.string :webpage_url
      t.string :helpdesk_url
      t.string :helpdesk_email
      t.string :security_contact_email
      t.string :certifications, array: true, default: []
      t.string :standards, array: true, default: []
      t.string :open_source_technologies, array: true, default: []
      t.string :changelog, array: true, default: []
      t.string :grant_project_names, array: true, default: []
      t.string :version
      t.string :geographical_availabilities, array: true, default: []
      t.string :geographic_locations, array: true, default: []
      t.string :language_availability, array: true, default: []
      t.datetime :last_update
      t.string :submission_policy_url
      t.string :preservation_policy_url
      t.boolean :version_control
      t.string :jurisdiction_id
      t.string :datasource_classification_id
      t.boolean :thematic, default: false
      t.boolean :horizontal, default: false
      t.string :user_manual_url
      t.string :terms_of_use_url
      t.string :privacy_policy_url
      t.string :access_policy_url
      t.string :resource_level_url
      t.string :training_information_url
      t.string :status_monitoring_url
      t.string :maintenance_url
      t.string :order_url
      t.string :payment_model_url
      t.string :pricing_url
      t.bigint :upstream_id
      t.datetime :synchronized_at
      t.timestamps
    end
  end
end
