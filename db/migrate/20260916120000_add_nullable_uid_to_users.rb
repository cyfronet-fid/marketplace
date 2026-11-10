# frozen_string_literal: true

# pl-marketplace's CreateUserIdentities (20260901103000) dropped users.uid and
# reads the uid from the primary UserIdentity instead. marketplace and
# whitelabel keep logging in through users.uid, so every variant ends with the
# column, nullable: pl gets it back empty, the others lose the NOT NULL that
# User's presence validation still enforces outside pl.
class AddNullableUidToUsers < ActiveRecord::Migration[7.2]
  def up
    if column_exists?(:users, :uid)
      change_column_null :users, :uid, true
    else
      add_column :users, :uid, :string
    end
  end

  # pl rows have no uid, so NOT NULL cannot be restored on every variant.
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
