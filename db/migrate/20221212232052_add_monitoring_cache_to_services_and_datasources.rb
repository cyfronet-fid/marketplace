# frozen_string_literal: true

class AddMonitoringCacheToServicesAndDatasources < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :availability_cache, :float
    add_column :services, :reliability_cache, :float
    add_column :datasources, :availability_cache, :float
    add_column :datasources, :reliability_cache, :float
  end
end
