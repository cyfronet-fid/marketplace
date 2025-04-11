# frozen_string_literal: true

class CreateObservedUserOffers < ActiveRecord::Migration[7.2]
  def change
    create_table :observed_user_offers do |t|
      t.belongs_to :user, foreign_key: true, index: true
      t.belongs_to :offer, foreign_key: true, index: true

      t.timestamps
    end
    add_index :observed_user_offers, %i[user_id offer_id], unique: true
  end
end
