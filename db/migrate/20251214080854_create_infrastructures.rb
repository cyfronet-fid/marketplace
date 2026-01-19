# frozen_string_literal: true
class CreateInfrastructures < ActiveRecord::Migration[7.2]
  def change
    create_table :infrastructures do |t|
      t.references :project_item, null: false, foreign_key: true

      # Infrastructure Manager details
      t.string :im_infrastructure_id
      t.string :im_base_url, null: false
      t.string :cloud_site, null: false

      # State tracking
      t.string :state, default: "pending", null: false
      t.datetime :last_state_check_at

      # Outputs from IM (e.g., jupyterhub_url, public_ip)
      t.jsonb :outputs, default: {}

      # Error tracking
      t.text :last_error
      t.integer :retry_count, default: 0

      t.timestamps
    end

    add_index :infrastructures, :im_infrastructure_id, unique: true
    add_index :infrastructures, :state
  end
end
