# frozen_string_literal: true

class CreateRaidAccesses < ActiveRecord::Migration[6.1]
  def change
    create_table :raid_accesses do |t|
      t.string :access_type, null: false
      t.date :embargo_expiry
      t.string :statement_text
      t.string :statement_lang
      t.references :raid_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
