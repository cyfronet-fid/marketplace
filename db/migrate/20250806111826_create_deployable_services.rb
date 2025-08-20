# frozen_string_literal: true
class CreateDeployableServices < ActiveRecord::Migration[7.2]
  def change
    create_table :deployable_services do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :tagline, null: false
      t.string :abbreviation
      t.string :url
      t.string :node
      t.string :version
      t.string :software_license
      t.datetime :last_update
      t.jsonb :creators, default: []
      t.string :slug
      t.string :status
      t.string :pid
      t.integer :upstream_id
      t.datetime :synchronized_at
      t.references :resource_organisation, null: false, foreign_key: { to_table: :providers }
      t.references :catalogue, null: true, foreign_key: true

      t.timestamps

      t.index :slug, unique: true
      t.index :pid
    end
  end
end
