# frozen_string_literal: true

class StripProviderToV6 < ActiveRecord::Migration[7.2]
  def up
    execute "DELETE FROM taggings WHERE taggable_type = 'Provider'"
    execute "DELETE FROM provider_scientific_domains"
    execute "DELETE FROM contacts WHERE contactable_type = 'Provider' AND type IN ('MainContact', 'PublicContact')"

    remove_column :providers, :street_name_and_number
    remove_column :providers, :postal_code
    remove_column :providers, :city
    remove_column :providers, :region
    remove_column :providers, :tagline
    remove_column :providers, :certifications
    remove_column :providers, :hosting_legal_entity_string
    remove_column :providers, :participating_countries
    remove_column :providers, :affiliations
    remove_column :providers, :national_roadmaps
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
