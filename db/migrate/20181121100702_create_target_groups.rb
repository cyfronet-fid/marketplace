# frozen_string_literal: true

class CreateTargetGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :target_groups do |t|
      t.string :name

      t.timestamps
    end
  end
end
