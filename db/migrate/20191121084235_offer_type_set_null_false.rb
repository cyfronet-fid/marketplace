# frozen_string_literal: true

class OfferTypeSetNullFalse < ActiveRecord::Migration[5.2]
  def up
    execute(<<~SQL)
      UPDATE offers
      SET offer_type = (
        SELECT service.service_type
        FROM services service
        WHERE service.id = service_id
      )
      SQL
    change_column_null :offers, :offer_type, false
  end

  def down
    change_column_null :offers, :offer_type, true
  end
end
