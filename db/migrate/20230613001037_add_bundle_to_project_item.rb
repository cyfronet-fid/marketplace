# frozen_string_literal: true

class AddBundleToProjectItem < ActiveRecord::Migration[6.1]
  def change
    add_column :project_items, :bundle_id, :integer, index: true
    add_foreign_key :project_items, :bundles, column: :bundle_id, on_delete: :nullify

    add_column :services, :bundles_count, :integer, null: false, default: 0
  end
end
