# frozen_string_literal: true

class AddDeploymentLinkToProjectItems < ActiveRecord::Migration[7.2]
  def change
    # whitelabel-marketplace added the column under its own migration version.
    add_column :project_items, :deployment_link, :string, if_not_exists: true
  end
end
