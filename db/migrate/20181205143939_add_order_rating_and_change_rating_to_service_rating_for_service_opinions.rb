# frozen_string_literal: true

class AddOrderRatingAndChangeRatingToServiceRatingForServiceOpinions < ActiveRecord::Migration[5.2]
  def change
    add_column :service_opinions, :order_rating, :integer, null: false
    rename_column :service_opinions, :rating, :service_rating
  end
end
