# frozen_string_literal: true

class AddAncestryToProjectItems < ActiveRecord::Migration[6.0]
  def change
    add_column :project_items, :ancestry, :string
    add_column :project_items, :ancestry_depth, :integer, default: 0
    add_index :project_items, :ancestry
  end
end
