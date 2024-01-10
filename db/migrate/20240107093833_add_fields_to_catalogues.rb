# frozen_string_literal: true

class AddFieldsToCatalogues < ActiveRecord::Migration[6.1]
  def change
    # Basic
    add_column :catalogues, :abbreviation, :string, default: ""
    add_column :catalogues, :website, :string, default: ""
    add_column :catalogues, :legal_entity, :boolean, default: false
    add_column :catalogues, :inclusion_criteria, :string, default: ""
    add_column :catalogues, :validation_process, :string, default: ""
    add_column :catalogues, :end_of_life, :string, default: ""
    add_column :catalogues, :status, :string, default: :published

    # Marketing
    add_column :catalogues, :description, :string, default: ""

    # Classification
    add_column :catalogues, :tags, :string, array: true, default: []
    add_column :catalogues, :structure_type, :string, array: true, default: []

    # Location
    add_column :catalogues, :street_name_and_number, :string, default: ""
    add_column :catalogues, :postal_code, :string, default: ""
    add_column :catalogues, :city, :string, default: ""
    add_column :catalogues, :region, :string, default: ""
    add_column :catalogues, :country, :string, default: ""

    # Dependencies
    add_column :catalogues, :participating_countries, :string, array: true, default: []
    add_column :catalogues, :affiliations, :string, array: true, default: []
  end
end
