# frozen_string_literal: true

class CreateRors < ActiveRecord::Migration[6.1]
  def change
    create_table :rors do |t|
      t.string :pid, null: false
      t.string :name, null: false
      t.string :acronyms, array: true, default: []
      t.string :aliases, array: true, default: []

      t.timestamps
    end
    add_index :rors, %i[pid], unique: true
  end
end
