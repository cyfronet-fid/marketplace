# frozen_string_literal: true

class RemoveServiceOrderTarget < ActiveRecord::Migration[6.0]
  def change
    exec_update "
      UPDATE offers
      SET
          oms_params = ('{\"order_target\": \"' || services.order_target || '\"}')::jsonb
      FROM services
      WHERE
            offers.service_id = services.id AND
            services.order_target <> '' AND
            offers.order_type = 'order_required' AND
            offers.internal = true;
    "
    remove_column :services, :order_target
  end
end
