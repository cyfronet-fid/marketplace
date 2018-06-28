class AddIssueIdToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :issue_id, :integer
  end
end
