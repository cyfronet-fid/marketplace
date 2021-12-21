# frozen_string_literal: true

class ChangeServiceAndOfferTypeValues < ActiveRecord::Migration[5.2]
  def up
    execute(<<~SQL)
      UPDATE services
      SET service_type = CASE
        WHEN service_type='normal' THEN 'orderable'
        WHEN service_type='catalog' THEN 'external'
      END
      WHERE service_type <> 'open_access';
      SQL

    execute(<<~SQL)
      UPDATE offers
      SET offer_type = CASE
        WHEN offer_type='normal' THEN 'orderable'
        WHEN offer_type='catalog' THEN 'external'
      END
      WHERE offer_type <> 'open_access';
      SQL
  end

  def down
    execute(<<~SQL)
      UPDATE services
      SET service_type = CASE
        WHEN service_type='orderable' THEN 'normal'
        WHEN service_type='external' THEN 'catalog'
      END
      WHERE service_type <> 'open_access';
      SQL

    execute(<<~SQL)
      UPDATE offers
      SET offer_type = CASE
        WHEN offer_type='orderable' THEN 'normal'
        WHEN offer_type='external' THEN 'catalog'
      END
      WHERE offer_type <> 'open_access';
      SQL
  end
end
