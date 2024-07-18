# frozen_string_literal: true

class RemoveOfferLinksTable < ActiveRecord::Migration[7.1]
  def change
    drop_table :offer_links
  end
end
