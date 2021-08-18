# frozen_string_literal: true

class AddAncestryToTargetUser < ActiveRecord::Migration[6.0]
  def change
    add_column :target_users, :ancestry, :string
    add_column :target_users, :ancestry_depth, :integer, default: 0
    add_index :target_users, :ancestry
  end
end
