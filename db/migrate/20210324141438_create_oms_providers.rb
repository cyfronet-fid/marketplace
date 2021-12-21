# frozen_string_literal: true

class CreateOMSProviders < ActiveRecord::Migration[6.0]
  def change
    create_table :oms_providers do |t|
      t.references :oms, null: false, foreign_key: { to_table: :oms }, index: true
      t.references :provider, null: false, foreign_key: true, index: true

      t.timestamps null: false
    end

    add_index :oms_providers, %i[oms_id provider_id], unique: true
  end
end
