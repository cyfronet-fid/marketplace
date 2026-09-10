# frozen_string_literal: true

class StripDatasourceToV6 < ActiveRecord::Migration[7.2]
  def up
    add_column :services, :research_product_types, :string, array: true, default: [], if_not_exists: true

    # pl-marketplace never ran this migration and still uses
    # persistent_identity_systems/submission_policy_url/preservation_policy_url
    # live — see arch_docs: docs/rationale/db-schema-comparison.md §2/§3.
    # Without this guard, the first `db:migrate` run against a real pl
    # production database would drop that data. submission_policy_url/
    # preservation_policy_url/harvestable move to service_pl_profiles via
    # BackfillServicePlProfiles (20260909100200); persistent_identity_systems
    # is kept as-is, already the right shape. datasource_id is dead even in
    # pl's own app (per the usage audit) but is left alone here too —
    # cleaning it up is a deliberate later step, not a side effect of this
    # guard.
    return if Mp::Variant.pl?

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
