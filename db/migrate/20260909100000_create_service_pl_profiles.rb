# frozen_string_literal: true

# 1:1 satellite table for the pl-marketplace-only `services` fields (see
# arch_docs: docs/rationale/db-schema-comparison.md §3). Kept off the shared
# `services` table so marketplace/whitelabel carry zero extra columns for
# fields they never use — same rule already applied to
# service_relationships/deployable_services. `Service#pl_profile` resolves to
# nil for those variants; nothing ever queries or joins this table for them.
class CreateServicePlProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :service_pl_profiles do |t|
      t.references :service, null: false, foreign_key: true, index: { unique: true }

      t.text :tagline
      t.string :language_availability, array: true, default: []
      t.string :dedicated_for, array: true
      t.string :resource_level_url
      t.string :manual_url
      t.string :helpdesk_url
      t.string :training_information_url
      t.text :activate_message
      t.string :helpdesk_email
      t.string :version
      t.string :maintenance_url
      t.string :payment_model_url
      t.string :pricing_url
      t.string :resource_geographic_locations, array: true, default: []
      t.string :certifications, array: true, default: []
      t.string :standards, array: true, default: []
      t.string :open_source_technologies, array: true, default: []
      t.text :changelog, array: true, default: []
      t.string :grant_project_names, array: true, default: []
      t.datetime :last_update, precision: nil
      t.string :related_platforms, array: true, default: []
      t.string :abbreviation
      t.boolean :horizontal, default: false, null: false
      t.float :availability_cache
      t.float :reliability_cache
      t.string :submission_policy_url
      t.string :preservation_policy_url
      t.string :security_contact_email

      t.timestamps
    end
  end
end
