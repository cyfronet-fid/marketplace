# frozen_string_literal: true

class AddAncestryDepthToCategory < ActiveRecord::Migration[5.2]
  def change
    add_column :categories, :ancestry_depth, :integer, default: 0
  end
end
