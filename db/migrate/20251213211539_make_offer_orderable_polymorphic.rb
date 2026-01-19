# frozen_string_literal: true

class MakeOfferOrderablePolymorphic < ActiveRecord::Migration[7.2]
  def up
    # Add polymorphic columns (nullable initially for safe data migration)
    add_column :offers, :orderable_type, :string
    add_column :offers, :orderable_id, :bigint

    # Migrate existing data from service_id
    execute <<-SQL.squish
      UPDATE offers
      SET orderable_type = 'Service', orderable_id = service_id
      WHERE service_id IS NOT NULL
    SQL

    # Migrate existing data from deployable_service_id (if column exists)
    execute <<-SQL.squish if column_exists?(:offers, :deployable_service_id)
        UPDATE offers
        SET orderable_type = 'DeployableService', orderable_id = deployable_service_id
        WHERE deployable_service_id IS NOT NULL AND orderable_id IS NULL
      SQL

    # Log warning about orphan offers (no service_id or deployable_service_id)
    # These are legacy data that will be excluded from queries via the polymorphic association
    orphan_count = execute("SELECT COUNT(*) FROM offers WHERE orderable_id IS NULL").first["count"].to_i
    if orphan_count.positive?
      Rails.logger.warn "Found #{orphan_count} orphan offers with no service. These will have NULL orderable."
    end

    # Add index for polymorphic lookup (allows NULLs for orphan offers)
    add_index :offers, %i[orderable_type orderable_id]

    # NOTE: We intentionally keep service_id and deployable_service_id columns
    # for rollback safety. They will be removed in a subsequent migration.
  end

  def down
    remove_index :offers, %i[orderable_type orderable_id]
    remove_column :offers, :orderable_type
    remove_column :offers, :orderable_id
  end
end
