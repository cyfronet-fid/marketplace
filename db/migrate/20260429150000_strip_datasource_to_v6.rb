# frozen_string_literal: true

class StripDatasourceToV6 < ActiveRecord::Migration[7.2]
  def up
    add_column :services, :research_product_types, :string, array: true, default: [], if_not_exists: true

    drop_table :persistent_identity_system_vocabularies, if_exists: true
    drop_table :persistent_identity_systems, if_exists: true

    remove_column :services, :submission_policy_url, :string, if_exists: true
    remove_column :services, :preservation_policy_url, :string, if_exists: true
    remove_column :services, :harvestable, :boolean, default: false, if_exists: true
    remove_column :services, :datasource_id, :string, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
