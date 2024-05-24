# frozen_string_literal: true

class AddNameToRaidOrganisation < ActiveRecord::Migration[6.1]
  def change
    add_column :raid_organisations, :name, :string, null: false
  end
end
