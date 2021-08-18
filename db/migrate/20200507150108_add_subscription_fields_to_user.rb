# frozen_string_literal: true

class AddSubscriptionFieldsToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :categories_updates, :boolean, default: false, null: false
    add_column :users, :research_areas_updates, :boolean, default: false, null: false
  end
end
