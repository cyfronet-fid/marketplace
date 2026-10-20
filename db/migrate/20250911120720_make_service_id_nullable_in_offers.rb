# frozen_string_literal: true

class MakeServiceIdNullableInOffers < ActiveRecord::Migration[7.2]
  def change
    # whitelabel-marketplace removed the column with its own offers conversion.
    change_column_null :offers, :service_id, true if column_exists?(:offers, :service_id)
  end
end
