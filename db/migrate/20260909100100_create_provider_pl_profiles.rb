# frozen_string_literal: true

# 1:1 satellite table for the pl-marketplace-only `providers` fields — same
# rationale as CreateServicePlProfiles (see
# arch_docs: docs/rationale/db-schema-comparison.md §3).
class CreateProviderPlProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :provider_pl_profiles do |t|
      t.references :provider, null: false, foreign_key: true, index: { unique: true }

      t.string :street_name_and_number
      t.string :postal_code
      t.string :city
      t.string :region
      t.string :certifications, array: true, default: []
      t.string :affiliations, array: true, default: []
      t.string :national_roadmaps, array: true, default: []

      t.timestamps
    end
  end
end
