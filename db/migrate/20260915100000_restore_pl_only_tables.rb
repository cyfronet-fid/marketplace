# frozen_string_literal: true

# Brings marketplace/whitelabel databases back to the same schema as pl.
# StripServiceToV6 (20260429141000) and StripDatasourceToV6 (20260429150000)
# dropped these tables on every variant except pl, where they still hold live
# data. All variants share one schema: the tables exist everywhere but are
# only used under Mp::Variant.pl?. `if_not_exists` makes this a no-op on pl
# and on any database built from db/schema.rb.
class RestorePlOnlyTables < ActiveRecord::Migration[7.2]
  def up
    create_table :service_target_users, if_not_exists: true do |t|
      t.bigint :service_id
      t.bigint :target_user_id
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.index %i[service_id target_user_id],
              unique: true,
              name: "index_service_target_users_on_service_id_and_target_user_id"
      t.index :service_id, name: "index_service_target_users_on_service_id"
      t.index :target_user_id, name: "index_service_target_users_on_target_user_id"
    end

    create_table :service_related_platforms, if_not_exists: true do |t|
      t.bigint :service_id
      t.bigint :platform_id
      t.index :platform_id, name: "index_service_related_platforms_on_platform_id"
      t.index %i[service_id platform_id],
              unique: true,
              name: "index_service_related_platforms_on_service_id_and_platform_id"
      t.index :service_id, name: "index_service_related_platforms_on_service_id"
    end

    create_table :service_relationships, if_not_exists: true do |t|
      t.bigint :source_id, null: false
      t.bigint :target_id, null: false
      t.datetime :created_at, precision: nil, null: false
      t.datetime :updated_at, precision: nil, null: false
      t.string :type
      t.index %i[source_id target_id type],
              unique: true,
              name: "index_service_relationships_on_source_id_and_target_id_and_type"
      t.index :source_id, name: "index_service_relationships_on_source_id"
      t.index :target_id, name: "index_service_relationships_on_target_id"
    end

    create_table :persistent_identity_systems, if_not_exists: true do |t|
      t.bigint :service_id, null: false
      t.bigint :entity_type_id
      t.timestamps
      t.index :entity_type_id, name: "index_persistent_identity_systems_on_entity_type_id"
      t.index %i[id entity_type_id], name: "index_persistent_identity_systems_on_id_and_entity_type_id"
      t.index %i[service_id entity_type_id], name: "index_persistent_id_systems"
      t.index :service_id, name: "index_persistent_identity_systems_on_service_id"
    end

    create_table :persistent_identity_system_vocabularies, if_not_exists: true do |t|
      t.bigint :persistent_identity_system_id
      t.bigint :vocabulary_id
      t.string :vocabulary_type
      t.timestamps
      t.index %i[persistent_identity_system_id vocabulary_id], name: "index_persistent_id_system_vocabularies"
      t.index :persistent_identity_system_id, name: "index_persistent_id_system"
      t.index :vocabulary_id, name: "index_persistent_id_system_on_vocabulary"
    end

    add_foreign_key :service_target_users, :services, if_not_exists: true
    add_foreign_key :service_target_users, :target_users, if_not_exists: true
    add_foreign_key :service_related_platforms, :platforms, if_not_exists: true
    add_foreign_key :service_related_platforms, :services, if_not_exists: true
    add_foreign_key :service_relationships, :services, column: :source_id, if_not_exists: true
    add_foreign_key :service_relationships, :services, column: :target_id, if_not_exists: true
    add_foreign_key :persistent_identity_systems, :services, if_not_exists: true
  end

  # Dropping these would destroy pl's live data.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
