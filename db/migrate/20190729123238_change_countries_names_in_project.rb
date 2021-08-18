# frozen_string_literal: true

class ChangeCountriesNamesInProject < ActiveRecord::Migration[5.2]
  def change
    rename_column :projects, :country_of_customer, :country_of_origin
    rename_column :projects, :country_of_collaboration, :countries_of_partnership
  end
end
