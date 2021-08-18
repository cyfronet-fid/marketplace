# frozen_string_literal: true

class AddNewUrlFieldsToService < ActiveRecord::Migration[6.0]
  def change
    add_column :services, :status_monitoring_url, :string
    add_column :services, :maintenance_url, :string
    add_column :services, :order_url, :string
    add_column :services, :payment_model_url, :string
    add_column :services, :pricing_url, :string
  end
end
