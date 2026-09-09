# frozen_string_literal: true

# Copies the legacy pl-shaped `services` columns into service_pl_profiles.
# Guarded once on Mp::Variant.pl? rather than column_exists? per column:
# this deployment's identity already tells us whether `services` still has
# this shape, and one clear guard reads better than many defensive checks
# scattered per column. marketplace/whitelabel never had these columns
# (StripServiceToV6, 20260429141000) and are a no-op here.
#
# Deliberately does NOT drop the legacy columns from `services` yet — that's
# a separate follow-up migration, run only after the application code
# (Service#pl_profile and friends) is deployed and reading from this table
# instead. Dropping columns the code doesn't use yet would be safe for the
# database but not for a deploy sequenced the other way around.
class BackfillServicePlProfiles < ActiveRecord::Migration[7.2]
  def up
    return unless Mp::Variant.pl?

    execute <<~SQL.squish
      INSERT INTO service_pl_profiles (
        service_id, tagline, language_availability, dedicated_for,
        resource_level_url, manual_url, helpdesk_url, training_information_url,
        activate_message, helpdesk_email, version, maintenance_url,
        payment_model_url, pricing_url, resource_geographic_locations,
        certifications, standards, open_source_technologies, changelog,
        grant_project_names, last_update, related_platforms, abbreviation,
        horizontal, availability_cache, reliability_cache,
        submission_policy_url, preservation_policy_url, security_contact_email,
        created_at, updated_at
      )
      SELECT
        id, tagline, language_availability, dedicated_for,
        resource_level_url, manual_url, helpdesk_url, training_information_url,
        activate_message, helpdesk_email, version, maintenance_url,
        payment_model_url, pricing_url, resource_geographic_locations,
        certifications, standards, open_source_technologies, changelog,
        grant_project_names, last_update, related_platforms, abbreviation,
        COALESCE(horizontal, false), availability_cache, reliability_cache,
        submission_policy_url, preservation_policy_url, security_contact_email,
        now(), now()
      FROM services
      ON CONFLICT (service_id) DO NOTHING
    SQL
  end

  def down
    return unless Mp::Variant.pl?

    execute "DELETE FROM service_pl_profiles"
  end
end
