# frozen_string_literal: true

class ChangeServiceTypeToOrderType < ActiveRecord::Migration[6.0]
  def change
    rename_column :services, :service_type, :order_type
  end
end
