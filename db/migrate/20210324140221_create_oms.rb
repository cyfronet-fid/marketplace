# frozen_string_literal: true

class CreateOMS < ActiveRecord::Migration[6.0]
  def change
    create_table :oms do |t|
      t.string :name, null: false, unique: true
      t.string :type, null: false, index: true
      t.jsonb :custom_params, null: true
      t.boolean :default, null: false, default: false, index: true
      t.string :trigger_url, null: true
      t.references :service, foreign_key: true, index: true

      t.timestamps null: false
    end
  end
end
