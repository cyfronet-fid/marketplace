# frozen_string_literal: true
class AddDeploymentLinkToProjectItems < ActiveRecord::Migration[7.2]
  def change
    add_column :project_items, :deployment_link, :string
  end
end
