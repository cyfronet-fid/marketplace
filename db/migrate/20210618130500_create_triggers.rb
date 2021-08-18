# frozen_string_literal: true

class CreateTriggers < ActiveRecord::Migration[6.0]
  def change
    create_table :oms_triggers do |t|
      t.belongs_to :oms, null: false, foreign_key: true

      t.string :url, null: false
      t.string :method, null: false

      t.timestamps null: false
    end

    execute "
      INSERT INTO oms_triggers (oms_id, url, method)
        SELECT oms.id, oms.trigger_url, 'post'
        FROM omses AS oms
        WHERE trigger_url IS NOT NULL AND trigger_url <> '';
    "

    remove_column :omses, :trigger_url
  end
end
