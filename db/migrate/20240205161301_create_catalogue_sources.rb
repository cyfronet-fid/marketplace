# frozen_string_literal: true

class CreateCatalogueSources < ActiveRecord::Migration[6.1]
  def change
    create_table :catalogue_sources do |t|
      t.string :eid, null: false
      t.string :source_type, null: false
      t.belongs_to :catalogue, index: true, null: false

      t.timestamps
    end
    add_index :catalogue_sources, %i[eid source_type catalogue_id], unique: true
  end
end
