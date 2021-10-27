# frozen_string_literal: true

class AddIidToProjectItemChange < ActiveRecord::Migration[5.2]
  def change
    add_column :project_item_changes, :iid, :integer
    add_index :project_item_changes, :iid
  end
end
