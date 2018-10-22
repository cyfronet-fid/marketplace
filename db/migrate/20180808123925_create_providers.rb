# frozen_string_literal: true

class CreateProviders < ActiveRecord::Migration[5.2]
  def change
    create_table :providers do |t|
      t.text :name, null: false

      t.timestamps
    end
  end
end
