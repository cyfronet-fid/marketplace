# frozen_string_literal: true

# Completes the reconciliation started by BackfillServicePlProfiles
# (20260909100200): now that Service#pl_profile and its delegated readers
# exist (app/models/service.rb), nothing reads these columns off `services`
# directly any more. `if_exists: true` on every column makes this safe
# regardless of starting shape — a no-op on marketplace/whitelabel, where
# StripServiceToV6 (20260429141000) already removed them, and the real
# removal on pl, whose data already lives in service_pl_profiles.
#
# Includes the 31 fields that moved to service_pl_profiles (the original 28
# plus restrictions, status_monitoring_url and harvestable, which the
# original usage audit wrongly called dead — pl's own app validates,
# permits and imports all three; see CreateServicePlProfiles and
# BackfillServicePlProfiles) AND provider_id/datasource_id, which really are
# unused in pl's app — nothing reads those, so they're dropped rather than
# carried forward as permanent unused columns.
class RemovePlLegacyColumnsFromServices < ActiveRecord::Migration[7.2]
  COLUMNS = %i[
    tagline language_availability dedicated_for resource_level_url manual_url helpdesk_url
    training_information_url activate_message helpdesk_email version maintenance_url payment_model_url
    pricing_url resource_geographic_locations certifications standards open_source_technologies changelog
    grant_project_names last_update related_platforms abbreviation horizontal availability_cache
    reliability_cache submission_policy_url preservation_policy_url security_contact_email
    restrictions status_monitoring_url harvestable
    provider_id datasource_id
  ].freeze

  def up
    COLUMNS.each { |column| remove_column :services, column, if_exists: true }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
