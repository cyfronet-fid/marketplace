# frozen_string_literal: true

class CreateServiceRelationships < ActiveRecord::Migration[5.2]
  def change
    create_table :service_relationships do |t|
      t.belongs_to :source, foreign_key: { to_table: :services }, null: false
      t.belongs_to :target, foreign_key: { to_table: :services }, null: false

      t.timestamps
    end

    add_index :service_relationships, %i[source_id target_id], unique: true
  end
end
