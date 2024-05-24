# frozen_string_literal: true

class CreatePositions < ActiveRecord::Migration[6.1]
  def change
    create_table :positions do |t|
      t.string :pid
      t.date :start_date
      t.date :end_date
      t.references :positionable, polymorphic: true, null: false

      t.timestamps
    end
  end
end
