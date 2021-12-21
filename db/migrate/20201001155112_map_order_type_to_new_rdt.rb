# frozen_string_literal: true

class MapOrderTypeToNewRdt < ActiveRecord::Migration[6.0]
  def up
    execute(<<~SQL)
      UPDATE offers
      SET internal = CASE
        WHEN order_type='orderable' THEN true
        WHEN order_type='external' THEN false
      END
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE project_items
      SET internal = CASE
        WHEN order_type='orderable' THEN true
        WHEN order_type='external' THEN false
      END
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE services
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE offers
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE project_items
      SET order_type = 'order_required'
      WHERE order_type <> 'open_access';
    SQL
  end

  def down
    execute(<<~SQL)
      UPDATE project_items
      SET order_type = CASE
        WHEN internal=true THEN 'orderable'
        WHEN internal=false THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE project_items
      SET order_type = CASE
        WHEN internal=true THEN 'orderable'
        WHEN internal=false THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE services
      SET order_type = CASE
        WHEN internal=true THEN 'orderable'
        WHEN internal=false THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL

    execute(<<~SQL)
      UPDATE offers
      SET order_type = CASE
        WHEN internal=true THEN 'orderable'
        WHEN internal=false THEN 'external'
      END
      WHERE order_type <> 'open_access';
    SQL
  end
end
