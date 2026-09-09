# frozen_string_literal: true

# Copies the legacy pl-shaped `providers` columns into provider_pl_profiles.
# See BackfillServicePlProfiles for the guard rationale and why the legacy
# columns aren't dropped here.
class BackfillProviderPlProfiles < ActiveRecord::Migration[7.2]
  def up
    return unless Mp::Variant.pl?

    execute <<~SQL.squish
      INSERT INTO provider_pl_profiles (
        provider_id, street_name_and_number, postal_code, city, region,
        certifications, affiliations, national_roadmaps, created_at, updated_at
      )
      SELECT
        id, street_name_and_number, postal_code, city, region,
        certifications, affiliations, national_roadmaps, now(), now()
      FROM providers
      ON CONFLICT (provider_id) DO NOTHING
    SQL
  end

  def down
    return unless Mp::Variant.pl?

    execute "DELETE FROM provider_pl_profiles"
  end
end
