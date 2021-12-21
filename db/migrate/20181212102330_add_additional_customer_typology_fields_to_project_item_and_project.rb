# frozen_string_literal: true

class AddAdditionalCustomerTypologyFieldsToProjectItemAndProject < ActiveRecord::Migration[5.2]
  def up
    add_column :project_items, :user_group_name, :text
    add_column :project_items, :project_name, :string
    add_column :project_items, :project_website_url, :string
    add_column :project_items, :company_name, :string
    add_column :project_items, :company_website_url, :string
    add_column :projects, :user_group_name, :string
    add_column :projects, :project_name, :string
    add_column :projects, :project_website_url, :string
    add_column :projects, :company_name, :string
    add_column :projects, :company_website_url, :string

    execute("UPDATE project_items SET user_group_name = 'Not provided' WHERE customer_typology = 'research'")
    execute(
      "UPDATE project_items SET project_name = 'Not provided', " \
        "project_website_url = 'https://not.provided' " \
        "WHERE customer_typology = 'private_company'"
    )

    execute(
      "UPDATE project_items SET company_name = 'Not provided', " \
        "company_website_url = 'https://not.provided' " \
        "WHERE customer_typology = 'private_company'"
    )

    execute("UPDATE projects SET user_group_name = 'Not provided' WHERE customer_typology = 'research'")
    execute(
      "UPDATE projects SET project_name = 'Not provided', " \
        "project_website_url = 'https://not.provided' " \
        "WHERE customer_typology = 'private_company'"
    )

    execute(
      "UPDATE projects SET company_name = 'Not provided', " \
        "company_website_url = 'https://not.provided' " \
        "WHERE customer_typology = 'private_company'"
    )
  end

  def down
    remove_column :project_items, :user_group_name
    remove_column :project_items, :project_name
    remove_column :project_items, :project_website_url
    remove_column :project_items, :company_name
    remove_column :project_items, :company_website_url
    remove_column :projects, :user_group_name
    remove_column :projects, :project_name
    remove_column :projects, :project_website_url
    remove_column :projects, :company_name
    remove_column :projects, :company_website_url
  end
end
