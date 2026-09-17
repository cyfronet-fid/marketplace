# frozen_string_literal: true

# pl-marketplace dropped service owners (its 20240807164825_remove_service_owners)
# while marketplace and whitelabel kept them, and the consolidated code reads
# User#owned_services_count and service_user_relationships on every variant
# (Backoffice::ServicePolicy, Backoffice::BundlePolicy, Service#owned_by?).
# Same rule as RestorePlOnlyTables: all variants share one schema, so a pl
# database gets the table and the counter back, empty. `if_not_exists` makes
# this a no-op on marketplace, whitelabel and any database built from
# db/schema.rb.
class RestoreServiceOwnerTables < ActiveRecord::Migration[7.2]
  def up
    create_table :service_user_relationships, if_not_exists: true do |t|
      t.bigint :service_id
      t.bigint :user_id
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.index :service_id, name: "index_service_user_relationships_on_service_id"
      t.index :user_id, name: "index_service_user_relationships_on_user_id"
    end

    add_foreign_key :service_user_relationships, :services, if_not_exists: true
    add_foreign_key :service_user_relationships, :users, if_not_exists: true

    add_column :users, :owned_services_count, :integer, default: 0, null: false, if_not_exists: true
  end

  # Dropping these would destroy marketplace's and whitelabel's live data.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
