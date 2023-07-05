# frozen_string_literal: true

class AddBundleExclusiveToOffer < ActiveRecord::Migration[6.1]
  def change
    add_column :offers, :bundle_exclusive, :boolean, default: false
    remove_column :offers, :bundled_offers_count
  end
end
