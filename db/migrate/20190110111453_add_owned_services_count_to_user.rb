# frozen_string_literal: true

class AddOwnedServicesCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :owned_services_count, :integer, null: false, default: 0
  end
end
