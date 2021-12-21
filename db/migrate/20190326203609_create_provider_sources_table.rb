# frozen_string_literal: true

class CreateProviderSourcesTable < ActiveRecord::Migration[5.2]
  def change
    create_table :provider_sources do |t|
      t.string :eid, null: false
      t.string :source_type, null: false
      t.belongs_to :provider, index: true, null: false
      t.timestamps
    end
    add_index :provider_sources, %i[eid source_type provider_id], unique: true
  end
end
