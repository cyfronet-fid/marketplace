class MapOrderTypeToNewRdt < ActiveRecord::Migration[6.0]
  def up
    execute(
        <<~SQL
      UPDATE offers
      SET external = CASE
        WHEN order_type='orderable' THEN false
        WHEN order_type='external' THEN true
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE services
      SET external = CASE
        WHEN order_type='orderable' THEN false
        WHEN order_type='external' THEN true
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE project_items
      SET external = CASE
        WHEN order_type='orderable' THEN false
        WHEN order_type='external' THEN true
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE services
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE offers
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE project_items
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL
    )
  end

  def down
    execute(
        <<~SQL
      UPDATE project_items
      SET order_type = CASE
        WHEN external=false THEN 'orderable'
        WHEN external=true THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE project_items
      SET order_type = CASE
        WHEN external=false THEN 'orderable'
        WHEN external=true THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE services
      SET order_type = CASE
        WHEN external=false THEN 'orderable'
        WHEN external=true THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL
    )

    execute(
        <<~SQL
      UPDATE offers
      SET order_type = CASE
        WHEN external=false THEN 'orderable'
        WHEN external=true THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL
    )
  end
end
