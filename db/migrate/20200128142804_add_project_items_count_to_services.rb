# frozen_string_literal: true

class AddProjectItemsCountToServices < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :project_items_count, :integer, null: false, default: 0
  end
end
