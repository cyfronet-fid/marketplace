# frozen_string_literal: true

class EnforceNotNullUniquePidOnProviders < ActiveRecord::Migration[7.2]
  def up
    backfill_blank_pids
    abort_on_duplicate_pids

    change_column_null :providers, :pid, false
    add_index :providers, :pid, unique: true
  end

  def down
    remove_index :providers, :pid
    change_column_null :providers, :pid, true
    # Backfilled UUIDs are intentionally left in place: they are already
    # exposed as friendly_id slugs and cannot be told apart from imported pids.
  end

  private

  def backfill_blank_pids
    select_values("SELECT id FROM providers WHERE pid IS NULL OR BTRIM(pid) = ''").each do |id|
      update("UPDATE providers SET pid = #{quote(SecureRandom.uuid)} WHERE id = #{quote(id)}")
    end
  end

  def abort_on_duplicate_pids
    duplicates = select_values("SELECT pid FROM providers GROUP BY pid HAVING COUNT(*) > 1")
    return if duplicates.empty?

    raise ActiveRecord::MigrationError,
          "Cannot add unique index on providers.pid, duplicate pids found: #{duplicates.join(", ")}"
  end

  def quote(value)
    connection.quote(value)
  end
end
