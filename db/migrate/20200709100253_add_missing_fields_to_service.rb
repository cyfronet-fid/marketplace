# frozen_string_literal: true

class AddMissingFieldsToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :resource_geographic_locations, :string, array: true, default: []
    add_column :services, :certifications, :string, array: true, default: []
    add_column :services, :standards, :string, array: true, default: []
    add_column :services, :open_source_technologies, :string, array: true, default: []
    add_column :services, :changelog, :text, array: true, default: []
    add_column :services, :grant_project_names, :string, array: true, default: []
    add_column :services, :multimedia, :string, array: true, default: []
    add_column :services, :privacy_policy_url, :string
    add_column :services, :use_cases_url, :string, array: true, default: []
    add_column :services, :last_update, :datetime
  end
end
