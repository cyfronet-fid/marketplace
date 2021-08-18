# frozen_string_literal: true

class EffectiveInternal < ActiveRecord::Migration[6.0]
  def change
    exec_update "UPDATE offers SET internal = true WHERE order_type = 'order_required' AND order_url = ''"
    exec_update "UPDATE project_items SET internal = true WHERE order_type = 'order_required' AND order_url = ''"
  end
end
