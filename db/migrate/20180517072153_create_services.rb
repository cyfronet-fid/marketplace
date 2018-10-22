# frozen_string_literal: true

class CreateServices < ActiveRecord::Migration[5.2]
  def change
    create_table :services do |t|
      t.string :title, null: false, index: true
      t.text :description, null: false, index: true

      t.timestamps
    end
  end
end
