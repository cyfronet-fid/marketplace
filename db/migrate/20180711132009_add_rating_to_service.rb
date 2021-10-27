# frozen_string_literal: true

class AddRatingToService < ActiveRecord::Migration[5.2]
  def change
    add_column :services, :rating, :decimal, default: 0.0, null: false, precision: 2, scale: 1
  end
end
