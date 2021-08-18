# frozen_string_literal: true

class AddInternalToOfferAndProjectItem < ActiveRecord::Migration[6.0]
  def change
    add_column :offers, :internal, :boolean, default: false
    add_column :project_items, :internal, :boolean, default: false
  end
end
