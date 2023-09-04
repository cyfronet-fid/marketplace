# frozen_string_literal: true

class AddIndexToBundleOffers < ActiveRecord::Migration[6.1]
  def change
    add_index :bundle_offers, %i[bundle_id offer_id], unique: true
  end
end
