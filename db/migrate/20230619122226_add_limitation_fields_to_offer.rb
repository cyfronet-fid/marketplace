# frozen_string_literal: true
class AddLimitationFieldsToOffer < ActiveRecord::Migration[6.1]
  def change
    add_column :offers, :limited, :boolean, default: false
    add_column :offers, :available_count, :integer, null: false, default: 0
  end
end
