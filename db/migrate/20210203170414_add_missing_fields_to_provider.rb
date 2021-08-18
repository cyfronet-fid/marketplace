# frozen_string_literal: true

class AddMissingFieldsToProvider < ActiveRecord::Migration[6.0]
  def change
    add_column :providers, :pid, :string
    add_column :providers, :abbreviation, :string
    add_column :providers, :website, :string
    add_column :providers, :legal_entity, :boolean
    add_column :providers, :description, :text
    add_column :providers, :multimedia, :string, array: true, default: []
    add_column :providers, :tagline, :text
    add_column :providers, :street_name_and_number, :string
    add_column :providers, :postal_code, :string
    add_column :providers, :city, :string
    add_column :providers, :region, :string
    add_column :providers, :country, :string
    add_column :providers, :certifications, :string, array: true, default: []
    add_column :providers, :hosting_legal_entity, :string
    add_column :providers, :participating_countries, :string, array: true, default: []
    add_column :providers, :affiliations, :string, array: true, default: []
    add_column :providers, :national_roadmaps, :string, array: true, default: []
    add_column :providers, :upstream_id, :integer
    add_column :providers, :synchronized_at, :datetime
  end
end
