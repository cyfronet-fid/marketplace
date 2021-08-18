# frozen_string_literal: true

class SetInternalInOffers < ActiveRecord::Migration[6.0]
  def change
    exec_update "UPDATE offers SET internal = 'false' WHERE order_type != 'order_required'"
    exec_update "UPDATE offers SET primary_oms_id = null WHERE internal = 'false'"
    exec_update "UPDATE offers SET oms_params = null WHERE internal = 'false'"
  end
end
