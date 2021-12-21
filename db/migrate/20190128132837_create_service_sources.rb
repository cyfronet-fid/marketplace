# frozen_string_literal: true

class CreateServiceSources < ActiveRecord::Migration[5.2]
  def change
    create_table :service_sources do |t|
      t.integer :eid, null: false
      t.string :source_type, null: false
      t.belongs_to :service, index: true, null: false
      t.timestamps
    end
    add_index :service_sources, %i[eid source_type service_id], unique: true
  end
end
