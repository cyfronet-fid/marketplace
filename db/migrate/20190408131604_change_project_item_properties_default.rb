# frozen_string_literal: true

class ChangeProjectItemPropertiesDefault < ActiveRecord::Migration[5.2]
  def up
    change_column :project_items, :properties, :jsonb, default: [], null: false
  end

  def down
    change_column :project_items, :properties, :jsonb, default: nil, null: true
  end
end
