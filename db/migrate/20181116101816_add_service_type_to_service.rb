# frozen_string_literal: true

class AddServiceTypeToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :service_type, :string, nil: false
    remove_column :services, :open_access
  end
end
