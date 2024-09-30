# frozen_string_literal: true

class CreateDescriptions < ActiveRecord::Migration[6.1]
  def change
    create_table :descriptions do |t|
      t.text :text, null: false
      t.string :language
      t.string :type, null: false
      t.string :description_type, null: false
      t.references :raid_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
