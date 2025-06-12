# frozen_string_literal: true

class AddUserIdToDataAdministrator < ActiveRecord::Migration[7.1]
  def change
    add_column :data_administrators, :user_id, :integer
    add_column :users, :providers_count, :integer, null: false, default: 0
    add_column :users, :catalogues_count, :integer, null: false, default: 0
    add_foreign_key :data_administrators, :users, index: true
  end
end
