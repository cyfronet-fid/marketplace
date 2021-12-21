# frozen_string_literal: true

class AddIssueStatusToProjectItems < ActiveRecord::Migration[5.2]
  def change
    # We want to have existing project_items to have 'jira_deleted' state, which should require manual handling
    add_column :project_items, :issue_status, :integer, default: 1, null: false

    # New project_items should have 'jira_uninitialized' issue_state, which will be changed afterwards when issue is created
    change_column_default :project_items, :issue_status, 2
  end
end
