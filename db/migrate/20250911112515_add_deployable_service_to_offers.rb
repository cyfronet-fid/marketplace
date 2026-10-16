# frozen_string_literal: true

class AddDeployableServiceToOffers < ActiveRecord::Migration[7.2]
  def change
    # whitelabel-marketplace made offers polymorphic under its own migration
    # version (orderable_type, orderable_id), so the temporary column of
    # marketplace's conversion is not necessary there.
    return if column_exists?(:offers, :orderable_type)

    add_reference :offers, :deployable_service, null: true, foreign_key: true, if_not_exists: true
  end
end
