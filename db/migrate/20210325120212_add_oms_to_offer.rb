# frozen_string_literal: true

class AddOMSToOffer < ActiveRecord::Migration[6.0]
  def change
    add_column :offers, :oms_params, :jsonb
    add_reference :offers, :primary_oms, foreign_key: { to_table: :oms }, index: true, null: true
  end
end
