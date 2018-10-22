# frozen_string_literal: true

class CreateProjectItems < ActiveRecord::Migration[5.2]
  def change
    create_table :project_items do |t|
      t.string :status, null: false
      t.belongs_to :service, null: false, index: true
      t.belongs_to :user, null: false, index: true

      t.timestamps
    end
  end
end
