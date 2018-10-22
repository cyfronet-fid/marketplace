# frozen_string_literal: true

class AddIidToProjectItemChange < ActiveRecord::Migration[5.2]
  def change
    add_column :project_item_changes, :iid, :integer, index: true
  end
end
