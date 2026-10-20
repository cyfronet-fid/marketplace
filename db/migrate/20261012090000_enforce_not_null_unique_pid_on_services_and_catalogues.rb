# frozen_string_literal: true

# pl-marketplace ran this migration under the same version, so a pl database
# skips it. Every step is also safe on a database that already has the
# constraints, for example one changed by hand.
class EnforceNotNullUniquePidOnServicesAndCatalogues < ActiveRecord::Migration[7.2]
  TABLES = %i[services catalogues].freeze

  def up
    TABLES.each do |table|
      backfill_blank_pids(table)
      abort_on_duplicate_pids(table)
      change_column_null table, :pid, false
    end

    # The non-unique index of services gives way to the unique one.
    remove_index :services, :pid, if_exists: true
    add_index :services, :pid, unique: true
    add_index :catalogues, :pid, unique: true, if_not_exists: true
  end

  def down
    remove_index :catalogues, :pid, if_exists: true
    remove_index :services, :pid, if_exists: true
    add_index :services, :pid

    TABLES.each { |table| change_column_null table, :pid, true }
    # Backfilled UUIDs are intentionally left in place: catalogues expose them
    # as friendly_id slugs and they cannot be told apart from imported pids.
  end

  private

  def backfill_blank_pids(table)
    # [[:space:]] also matches tabs and newlines, which BTRIM (spaces only) leaves in place
    select_values("SELECT id FROM #{table} WHERE pid IS NULL OR pid ~ '^[[:space:]]*$'").each do |id|
      update("UPDATE #{table} SET pid = #{quote(SecureRandom.uuid)} WHERE id = #{quote(id)}")
    end
  end

  def abort_on_duplicate_pids(table)
    duplicates = select_values("SELECT pid FROM #{table} GROUP BY pid HAVING COUNT(*) > 1")
    return if duplicates.empty?

    raise ActiveRecord::MigrationError,
          "Cannot add unique index on #{table}.pid, duplicate pids found: #{duplicates.join(", ")}"
  end

  def quote(value)
    connection.quote(value)
  end
end
