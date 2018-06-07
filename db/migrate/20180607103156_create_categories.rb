# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :categories do |t|
      t.string :name, null: false, index: true
      t.string :description, index: true
      t.string :ancestry, index: true

      t.timestamps
    end
  end
end
