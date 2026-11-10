# frozen_string_literal: true

# pl-marketplace ran this migration under the same version, so a pl database
# skips it. The deployment databases of the other variants hold duplicate
# pids, thus the migration resolves them instead of an abort.
class EnforceNotNullUniquePidOnProviders < ActiveRecord::Migration[7.2]
  def up
    backfill_blank_pids
    resolve_duplicate_pids

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

  # Of the rows that share a pid, the newest row that is not deleted keeps
  # the pid. A NULL status counts as not deleted. Each other row gets a UUID,
  # like a backfilled blank pid.
  def resolve_duplicate_pids
    select_values("SELECT pid FROM providers GROUP BY pid HAVING COUNT(*) > 1").each do |pid|
      superseded_ids =
        select_values(
          "SELECT id FROM providers WHERE pid = #{quote(pid)} " \
          "ORDER BY (status IS NOT DISTINCT FROM 'deleted') ASC, updated_at DESC, id DESC OFFSET 1"
        )
      superseded_ids.each do |id|
        new_pid = SecureRandom.uuid
        say "providers.id=#{id}: duplicate pid #{pid} replaced with #{new_pid}"
        update("UPDATE providers SET pid = #{quote(new_pid)} WHERE id = #{quote(id)}")
      end
    end
  end

  def quote(value)
    connection.quote(value)
  end
end
