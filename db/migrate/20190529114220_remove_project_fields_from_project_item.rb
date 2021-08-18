# frozen_string_literal: true

class RemoveProjectFieldsFromProjectItem < ActiveRecord::Migration[5.2]
  def change
    remove_column :project_items, :access_reason, :text
    remove_column :project_items, :customer_typology, :string
    remove_column :project_items, :user_group_name, :string
    remove_column :project_items, :project_name, :string
    remove_column :project_items, :project_website_url, :string
    remove_column :project_items, :company_name, :string
    remove_column :project_items, :company_website_url, :string
  end
end
