# frozen_string_literal: true
class CreateGuideline < ActiveRecord::Migration[6.1]
  def change
    create_table :guidelines do |t|
      t.string :title
      t.string :eid

      t.timestamps
    end
    add_index :guidelines, :eid, unique: true
  end
end
