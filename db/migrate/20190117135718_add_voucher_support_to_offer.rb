# frozen_string_literal: true

class AddVoucherSupportToOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :voucherable, :boolean, default: false, null: false
  end
end
