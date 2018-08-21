class AddIssueStatusToOrders < ActiveRecord::Migration[5.2]
  def change
    # We want to have existing orders to have 'jira_deleted' state, which should require manual handling
    add_column :orders, :issue_status, :integer, default: 1, null: false
    # New orders should have 'jira_uninitialized' issue_state, which will be changed afterwards when issue is created
    change_column_default :orders, :issue_status, 2
  end
end
