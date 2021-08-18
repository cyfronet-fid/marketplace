# frozen_string_literal: true

class CreateVocabulary < ActiveRecord::Migration[6.0]
  def change
    create_table :vocabularies do |t|
      t.string :eid, null: false
      t.string :name, null: false
      t.string :description, null: true, default: nil
      t.string :type, null: false
      t.string :ancestry, index: true
      t.integer :ancestry_depth, default: 0
      t.jsonb :extras, null: true, default: nil

      t.timestamps
    end
  end
end
