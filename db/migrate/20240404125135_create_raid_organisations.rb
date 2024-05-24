# frozen_string_literal: true

class CreateRaidOrganisations < ActiveRecord::Migration[6.1]
  def change
    create_table :raid_organisations do |t|
      t.string :pid, null: false
      t.references :raid_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
