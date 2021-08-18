# frozen_string_literal: true

class AddVoucherToProjectItem < ActiveRecord::Migration[5.2]
  def change
    add_column :project_items, :voucher_id, :string, default: "", null: false
  end
end
