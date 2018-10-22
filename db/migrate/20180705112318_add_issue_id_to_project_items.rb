# frozen_string_literal: true

class AddIssueIdToProjectItems < ActiveRecord::Migration[5.2]
  def change
    add_column :project_items, :issue_id, :integer
  end
end
