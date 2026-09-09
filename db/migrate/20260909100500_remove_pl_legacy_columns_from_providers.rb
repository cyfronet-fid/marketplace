# frozen_string_literal: true

# Completes the reconciliation started by BackfillProviderPlProfiles
# (20260909100300) — see RemovePlLegacyColumnsFromServices for the same
# rationale. Includes the 7 fields that moved to provider_pl_profiles and
# the 3 confirmed dead even in pl's own app (tagline, hosting_legal_entity_string,
# participating_countries — arch_docs: docs/rationale/db-schema-comparison.md §3).
class RemovePlLegacyColumnsFromProviders < ActiveRecord::Migration[7.2]
  COLUMNS = %i[
    street_name_and_number postal_code city region certifications affiliations national_roadmaps
    tagline hosting_legal_entity_string participating_countries
  ].freeze

  def up
    COLUMNS.each { |column| remove_column :providers, column, if_exists: true }
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
