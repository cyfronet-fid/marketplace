# frozen_string_literal: true

class CreateTitles < ActiveRecord::Migration[6.1]
  def change
    create_table :titles do |t|
      t.string :text, null: false
      t.string :language
      t.string :title_type, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.references :raid_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
