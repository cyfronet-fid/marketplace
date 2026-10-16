# frozen_string_literal: true

class CreateDeployableServiceSources < ActiveRecord::Migration[7.2]
  def change
    # whitelabel-marketplace created this table under its own migration version.
    create_table :deployable_service_sources, if_not_exists: true do |t|
      t.string :eid, null: false
      t.string :source_type, null: false
      t.references :deployable_service, null: false, foreign_key: true
      t.jsonb :errored

      t.timestamps

      t.index %i[eid source_type deployable_service_id],
              name: "index_ds_sources_on_eid_and_source_type_and_ds_id",
              unique: true
    end
  end
end
