# frozen_string_literal: true

class CreateRaidProjects < ActiveRecord::Migration[6.1]
  def change
    create_table :raid_projects do |t|
      t.date :start_date, null: false
      t.date :end_date

      t.timestamps
    end
  end
end
