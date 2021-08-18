# frozen_string_literal: true

class AddPropertiesToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_column :project_items, :properties, :jsonb
  end
end
