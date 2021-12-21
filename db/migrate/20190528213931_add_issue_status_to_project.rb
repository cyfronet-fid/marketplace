# frozen_string_literal: true

class AddIssueStatusToProject < ActiveRecord::Migration[5.2]
  def change
    # We want to have existing project_items to have 'jira_to_migrate' state, which should require manual handling
    add_column :projects, :issue_status, :integer, default: 100, null: false

    # New project_items should have 'jira_uninitialized' issue_state, which will be changed afterwards when issue is created
    change_column_default :projects, :issue_status, to: 2, from: 100

    add_column :projects, :issue_key, :string
  end
end
