# frozen_string_literal: true

class AddCountersToOffers < ActiveRecord::Migration[7.2]
  def change
    add_column :offers, :limited_availability, :boolean, default: false
    add_column :offers, :availability_count, :bigint, default: 0
    add_column :offers, :availability_unit, :string, default: "piece"
  end
end
