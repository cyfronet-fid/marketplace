# frozen_string_literal: true

class AddHarvestableToServices < ActiveRecord::Migration[6.1]
  def change
    add_column :services, :harvestable, :boolean, default: false
  end
end
