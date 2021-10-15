# frozen_string_literal: true

class AddBundledOffersCountToOffer < ActiveRecord::Migration[5.2]
  def change
    add_column :offers, :bundled_offers_count, :integer, null: false, default: 0
  end
end
