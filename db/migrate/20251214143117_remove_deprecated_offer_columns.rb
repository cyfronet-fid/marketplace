# frozen_string_literal: true

class RemoveDeprecatedOfferColumns < ActiveRecord::Migration[7.2]
  def up
    # Remove indexes first
    remove_index :offers, name: "index_offers_on_deployable_service_id", if_exists: true
    remove_index :offers, name: "index_offers_on_service_id_and_iid", if_exists: true
    remove_index :offers, name: "index_offers_on_service_id", if_exists: true

    # Remove the deprecated columns
    # These were replaced by the polymorphic orderable_type/orderable_id columns
    remove_column :offers, :service_id, :bigint
    remove_column :offers, :deployable_service_id, :bigint
  end

  def down
    # Restore columns
    add_reference :offers, :service, foreign_key: true
    add_reference :offers, :deployable_service, foreign_key: true

    # Restore unique index on service_id and iid
    add_index :offers, %i[service_id iid], unique: true

    # Restore data from orderable columns
    execute <<-SQL.squish
      UPDATE offers
      SET service_id = orderable_id
      WHERE orderable_type = 'Service'
    SQL

    execute <<-SQL.squish
      UPDATE offers
      SET deployable_service_id = orderable_id
      WHERE orderable_type = 'DeployableService'
    SQL
  end
end
