# frozen_string_literal: true

class CreateProjectItemChanges < ActiveRecord::Migration[5.2]
  def change
    create_table :project_item_changes do |t|
      t.string :status
      t.text :message
      t.belongs_to :project_item, null: false, index: true

      t.timestamps
    end
  end
end
