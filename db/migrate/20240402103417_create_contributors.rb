# frozen_string_literal: true

class CreateContributors < ActiveRecord::Migration[6.1]
  def change
    create_table :contributors do |t|
      t.string :pid_type, null: false
      t.string :pid, null: false
      t.boolean :leader, null: false
      t.boolean :contact, null: false
      t.string :roles, array: true, default: []
      t.references :raid_project, null: false, foreign_key: true

      t.timestamps
    end
  end
end
