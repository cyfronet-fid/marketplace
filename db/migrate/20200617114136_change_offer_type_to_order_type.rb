# frozen_string_literal: true

class ChangeOfferTypeToOrderType < ActiveRecord::Migration[6.0]
  def change
    rename_column :offers, :offer_type, :order_type
    rename_column :project_items, :offer_type, :order_type
  end
end
