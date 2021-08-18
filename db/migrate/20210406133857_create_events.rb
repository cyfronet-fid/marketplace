# frozen_string_literal: true

class CreateEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :events do |t|
      t.string :action, null: false
      t.references :eventable, polymorphic: true, index: true
      t.jsonb :updates, array: true
      t.jsonb :additional_info, null: false

      t.timestamps null: false
    end
  end
end
