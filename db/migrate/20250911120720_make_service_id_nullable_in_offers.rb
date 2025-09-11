# frozen_string_literal: true
class MakeServiceIdNullableInOffers < ActiveRecord::Migration[7.2]
  def change
    change_column_null :offers, :service_id, true
  end
end
