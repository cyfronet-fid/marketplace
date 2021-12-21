# frozen_string_literal: true

class AddWebpageToOffer < ActiveRecord::Migration[5.2]
  def up
    add_column :offers, :webpage, :string

    execute(<<~SQL)
      UPDATE offers
      SET webpage = (
        SELECT connected_url
        fROM services s
        WHERE s.id = service_id
      )
      SQL

    remove_column :services, :connected_url, :string
  end

  def down
    add_column :services, :connected_url, :string

    execute(<<~SQL)
      UPDATE services s
      SET connected_url = (
        SELECT o.webpage
        FROM offers o
        WHERE s.id = o.service_id AND o.webpage IS NOT NULL
        LIMIT 1
      )
      SQL
    remove_column :offers, :webpage, :string
  end
end
