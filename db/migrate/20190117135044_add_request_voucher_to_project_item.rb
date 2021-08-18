# frozen_string_literal: true

class AddRequestVoucherToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_column :project_items, :request_voucher, :boolean, default: false, null: false
  end
end
