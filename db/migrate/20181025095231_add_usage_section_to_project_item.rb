# frozen_string_literal: true

class AddUsageSectionToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_column :project_items, :customer_typology, :string
    add_column :project_items, :access_reason, :text
    add_column :project_items, :additional_information, :text
  end
end
