# frozen_string_literal: true

class AddServiceOrderTargetToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :order_target, :string, null: false, default: ""
  end
end
