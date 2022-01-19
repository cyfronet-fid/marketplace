# frozen_string_literal: true

class SetBlankOrderTypeInService < ActiveRecord::Migration[6.1]
  def change
    exec_update "UPDATE services SET order_type = 'open_access' WHERE order_type = '' OR order_type IS NULL"
    change_column :services, :order_type, :string, null: false
  end
end
