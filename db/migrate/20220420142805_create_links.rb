# frozen_string_literal: true

class CreateLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :links do |t|
      t.string :name
      t.string :url
      t.string :type, null: false
      t.string :linkable_type
      t.belongs_to :linkable, index: true, null: false

      t.timestamps
    end
    add_index :links, %i[id linkable_id linkable_type], unique: true
  end
end
