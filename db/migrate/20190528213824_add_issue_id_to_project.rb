# frozen_string_literal: true

class AddIssueIdToProject < ActiveRecord::Migration[5.2]
  def change
    add_column :projects, :issue_id, :integer
  end
end
