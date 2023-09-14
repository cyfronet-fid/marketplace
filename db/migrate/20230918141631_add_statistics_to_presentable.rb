# frozen_string_literal: true

class AddStatisticsToPresentable < ActiveRecord::Migration[6.1]
  def change
    all_presentable_tables = %i[providers services offers bundles]
    tables = %i[bundles offers]

    tables.each { |table| add_column table, :project_items_count, :integer, null: false, default: 0 }
    all_presentable_tables.each { |table| add_column table, :usage_counts_views, :integer, null: false, default: 0 }
  end
end
