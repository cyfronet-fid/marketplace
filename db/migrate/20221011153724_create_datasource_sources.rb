# frozen_string_literal: true

class CreateDatasourceSources < ActiveRecord::Migration[6.1]
  def change
    create_table :datasource_sources do |t|
      t.string "eid", null: false
      t.string "source_type", null: false
      t.belongs_to :datasource, index: true, null: false
      t.jsonb "errored"

      t.timestamps
    end
    add_index :datasource_sources,
              %i[eid source_type datasource_id],
              unique: true,
              name: "index_datasource_sources_on_eid_type_and_id"
  end
end
