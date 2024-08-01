# frozen_string_literal: true

class RemoveServiceOwners < ActiveRecord::Migration[7.1]
  def change
    drop_table :service_user_relationships
    remove_column :users, :owned_services_count
  end
end
