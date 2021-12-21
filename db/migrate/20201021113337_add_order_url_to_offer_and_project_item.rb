# frozen_string_literal: true

class AddOrderUrlToOfferAndProjectItem < ActiveRecord::Migration[6.0]
  def up
    add_column :offers, :order_url, :string
    add_column :project_items, :order_url, :string

    execute(<<~SQL)
      UPDATE offers
      SET order_url = (
        SELECT order_url
        FROM services s
        WHERE s.id = service_id
      )
    SQL

    execute(<<~SQL)
      UPDATE project_items
      SET order_url = (
        SELECT order_url
        FROM offers o
        WHERE o.id = offer_id
      )
    SQL
  end

  def down
    remove_column :project_items, :order_url
    remove_column :offers, :order_url
  end
end
